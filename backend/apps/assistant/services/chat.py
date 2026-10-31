import logging
from collections.abc import Callable
from typing import Any

import anthropic
from django.conf import settings

from apps.assistant import repositories
from apps.assistant.models import Conversation, ConversationStatus
from apps.assistant.services.mcp_gateway import GatewayError, McpGateway, ToolSpec

logger = logging.getLogger(__name__)

MAX_TOKENS = 16000
MAX_STEPS = 8
TITLE_LENGTH = 60
FALLBACK_BETA = "server-side-fallback-2026-07-01"

SYSTEM_PROMPT = """Sei l'assistente di ripasso di FlashCardApp, l'app con cui l'utente ripassa le flashcard \
del suo vault Obsidian. Lo aiuti a preparare mazzi provvisori: "oggi ripasso MCP e Raft", "le card che ho \
sbagliato negli ultimi giorni", "quelle che ho sbagliato prima".

Come lavori:
- Usa i tool per conoscere argomenti e mazzi: non inventare titoli di note né numeri.
- Prepara sempre l'anteprima e descrivila in poche righe (quante card per argomento, avvisi compresi). Poi \
chiama subito flashcards_create_temporary_deck con il draft_id: l'app mostra all'utente un pulsante per \
confermare o rifiutare, non serve chiedergli conferma a parole.
- Se l'utente rifiuta, chiedigli cosa vuole cambiare.
- Le flashcard le scrive l'utente nel vault: non ne generi di nuove e non le modifichi.

Rispondi in italiano, in modo breve e diretto."""

REJECTED = "L'utente non ha confermato: non è stato creato niente. Chiedigli cosa vuole cambiare."


class ChatError(Exception):
    pass


class ConversationNotFound(Exception):
    pass


class ConversationBusy(Exception):
    pass


class ClaudeClient:

    def __init__(self):
        self.client = anthropic.Anthropic(timeout=120.0, max_retries=2)

    def create(self, tools: list[dict[str, Any]], messages: list[dict[str, Any]]):
        return self.client.beta.messages.create(
            model=settings.ASSISTANT_MODEL,
            max_tokens=MAX_TOKENS,
            system=SYSTEM_PROMPT,
            tools=tools,
            messages=messages,
            thinking={"type": "adaptive"},
            output_config={"effort": settings.ASSISTANT_EFFORT},
            cache_control={"type": "ephemeral"},
            betas=[FALLBACK_BETA],
            fallbacks="default",
        )


def start_conversation(user) -> Conversation:
    return repositories.create_conversation(user)


def send_message(user, conversation_id: int, text: str, *, claude=None, gateway=None) -> Conversation:
    conversation = _get(user, conversation_id)
    if not repositories.claim(conversation, ConversationStatus.IDLE):
        raise ConversationBusy(conversation_id)
    if not conversation.title:
        repositories.set_title(conversation, text.strip()[:TITLE_LENGTH])
    repositories.append_message(conversation, "user", [{"type": "text", "text": text}])
    return _run_turn(conversation, claude, gateway or McpGateway(user))


def confirm(user, conversation_id: int, approve: bool, *, claude=None, gateway=None) -> Conversation:
    conversation = _get(user, conversation_id)
    if not repositories.claim(conversation, ConversationStatus.WAITING_CONFIRMATION):
        raise ConversationBusy(conversation_id)
    gateway = gateway or McpGateway(user)

    def execute():
        tools = {tool.name: tool for tool in gateway.list_tools()}
        last = repositories.messages(conversation)[-1]
        results = [
            _execute(gateway, block, tools)
            if approve or not _needs_confirmation(block, tools)
            else _tool_result(block, REJECTED, is_error=True)
            for block in _tool_uses(last.content)
        ]
        repositories.append_message(conversation, "user", results)

    return _run_turn(conversation, claude, gateway, before=execute)


def delete_conversation(user, conversation_id: int) -> None:
    repositories.delete_conversation(_get(user, conversation_id))


def _run_turn(conversation: Conversation, claude, gateway: McpGateway, before: Callable[[], None] | None = None):
    final_status = ConversationStatus.WAITING_CONFIRMATION if before is not None else ConversationStatus.IDLE
    try:
        if before is not None:
            before()
            final_status = ConversationStatus.IDLE
        final_status = _loop(conversation, claude or ClaudeClient(), gateway)
    except GatewayError as exc:
        logger.warning("Chat %s: %s", conversation.pk, exc)
        raise ChatError("Il server MCP non risponde: controlla che il servizio `mcp` sia acceso.") from exc
    except anthropic.AuthenticationError as exc:
        raise ChatError("Chiave della Claude API mancante o non valida: imposta ANTHROPIC_API_KEY.") from exc
    except anthropic.RateLimitError as exc:
        raise ChatError("Troppe richieste alla Claude API: riprova tra poco.") from exc
    except anthropic.APIConnectionError as exc:
        raise ChatError("La Claude API non risponde: riprova tra poco.") from exc
    except anthropic.APIStatusError as exc:
        logger.error("Chat %s: errore della Claude API %s: %s", conversation.pk, exc.status_code, exc.message)
        raise ChatError(f"Errore della Claude API ({exc.status_code}).") from exc
    finally:
        repositories.set_status(conversation, final_status)
    return conversation


def _loop(conversation: Conversation, claude, gateway: McpGateway) -> str:
    tools = gateway.list_tools()
    by_name = {tool.name: tool for tool in tools}
    for _ in range(MAX_STEPS):
        history = [{"role": m.role, "content": m.content} for m in repositories.messages(conversation)]
        response = claude.create([tool.for_claude() for tool in tools], history)
        content = [block for block in map(_dump, response.content) if block.get("type") != "fallback"]
        if content:
            repositories.append_message(conversation, "assistant", content)

        if response.stop_reason == "refusal":
            raise ChatError("Claude ha rifiutato di rispondere a questa richiesta.")
        if response.stop_reason == "max_tokens":
            raise ChatError("La risposta era troppo lunga ed è stata interrotta.")
        if response.stop_reason != "tool_use":
            return ConversationStatus.IDLE

        tool_uses = _tool_uses(content)
        if any(_needs_confirmation(block, by_name) for block in tool_uses):
            return ConversationStatus.WAITING_CONFIRMATION
        repositories.append_message(conversation, "user", [_execute(gateway, block, by_name) for block in tool_uses])
    raise ChatError("L'assistente ha fatto troppi passi senza concludere.")


def _execute(gateway: McpGateway, block: dict, tools: dict[str, ToolSpec]) -> dict:
    if block["name"] not in tools:
        return _tool_result(block, f"Tool {block['name']} inesistente.", is_error=True)
    outcome = gateway.call_tool(block["name"], block.get("input") or {})
    return _tool_result(block, outcome.text, is_error=outcome.is_error)


def _tool_result(block: dict, text: str, *, is_error: bool) -> dict:
    result = {"type": "tool_result", "tool_use_id": block["id"], "content": text}
    if is_error:
        result["is_error"] = True
    return result


def _needs_confirmation(block: dict, tools: dict[str, ToolSpec]) -> bool:
    tool = tools.get(block["name"])
    return tool is not None and tool.needs_confirmation


def _tool_uses(content: list[dict]) -> list[dict]:
    return [block for block in content if block.get("type") == "tool_use"]


def _dump(block) -> dict:
    return block if isinstance(block, dict) else block.model_dump(mode="json", exclude_none=True)


def _get(user, conversation_id: int) -> Conversation:
    conversation = repositories.get_conversation(user, conversation_id)
    if conversation is None:
        raise ConversationNotFound(conversation_id)
    return conversation
