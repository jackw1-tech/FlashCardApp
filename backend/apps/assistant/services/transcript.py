import json

from apps.assistant import repositories
from apps.assistant.models import Conversation, ConversationStatus
from apps.assistant.services.chat import REJECTED

PREVIEW = "flashcards_preview_temporary_deck"
CREATE = "flashcards_create_temporary_deck"

ACTIVITY = {
    "flashcards_find_topics": "Ho guardato i tuoi argomenti",
    PREVIEW: "Ho preparato l'anteprima",
    CREATE: "Creazione del mazzo",
    "flashcards_list_temporary_decks": "Ho guardato i tuoi mazzi provvisori",
}


def render(conversation: Conversation, error: str | None = None) -> dict:
    items: list[dict] = []
    tool_names: dict[str, str] = {}
    previews: dict[int, dict] = {}
    last_tool_uses: list[dict] = []

    for message in repositories.messages(conversation):
        if message.role == "assistant":
            last_tool_uses = []
        for block in message.content:
            kind = block.get("type")
            if kind == "text" and block.get("text", "").strip():
                items.append({"kind": message.role, "text": block["text"]})
            elif kind == "tool_use":
                tool_names[block["id"]] = block["name"]
                last_tool_uses.append(block)
                items.append({"kind": "activity", "text": ACTIVITY.get(block["name"], block["name"])})
            elif kind == "tool_result":
                _result_item(block, tool_names.get(block["tool_use_id"]), previews, items)

    return {
        "id": conversation.pk,
        "title": conversation.title,
        "status": conversation.status,
        "items": items,
        "pending": _pending(conversation, last_tool_uses, previews),
        "error": error,
    }


def summary(conversation: Conversation) -> dict:
    return {
        "id": conversation.pk,
        "title": conversation.title,
        "status": conversation.status,
        "updated_at": conversation.updated_at.isoformat(),
    }


def _result_item(block: dict, tool: str | None, previews: dict[int, dict], items: list[dict]) -> None:
    if block.get("is_error"):
        if tool == CREATE and block.get("content") == REJECTED:
            items.append({"kind": "activity", "text": "Hai rifiutato il mazzo"})
        return
    data = _json(block.get("content"))
    if tool == PREVIEW and "draft_id" in data:
        previews[data["draft_id"]] = data
    elif tool == CREATE and "temporary_deck_id" in data:
        items.append(
            {
                "kind": "deck_created",
                "text": data["name"],
                "temporary_deck_id": data["temporary_deck_id"],
                "total": data["total"],
            }
        )


def _pending(conversation: Conversation, tool_uses: list[dict], previews: dict[int, dict]) -> dict | None:
    if conversation.status != ConversationStatus.WAITING_CONFIRMATION:
        return None
    create = next((block for block in tool_uses if block["name"] == CREATE), None)
    if create is None:
        return {"action": ACTIVITY.get(tool_uses[0]["name"], tool_uses[0]["name"]) if tool_uses else "", "deck": None}
    preview = previews.get((create.get("input") or {}).get("draft_id"))
    deck = None
    if preview is not None:
        deck = {
            "name": preview["name"],
            "total": preview["total"],
            "by_note": [{"note": n["note"], "taken": n["taken"]} for n in preview["by_note"]],
            "adjustments": preview["adjustments"],
        }
    return {"action": "Creare il mazzo provvisorio?", "deck": deck}


def _json(content) -> dict:
    if not isinstance(content, str):
        return {}
    try:
        value = json.loads(content)
    except json.JSONDecodeError:
        return {}
    return value if isinstance(value, dict) else {}
