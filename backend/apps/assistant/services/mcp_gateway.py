import asyncio
from dataclasses import dataclass
from typing import Any

import httpx2
from django.conf import settings
from mcp import Client
from mcp.client.streamable_http import streamable_http_client

from apps.assistant.mcp.auth import issue_token

TIMEOUT_SECONDS = 30


class GatewayError(Exception):
    pass


@dataclass(frozen=True)
class ToolSpec:
    name: str
    title: str
    description: str
    input_schema: dict[str, Any]
    needs_confirmation: bool

    def for_claude(self) -> dict[str, Any]:
        return {"name": self.name, "description": self.description, "input_schema": self.input_schema}


@dataclass(frozen=True)
class ToolOutcome:
    text: str
    is_error: bool


class McpGateway:
    def __init__(self, user, url: str | None = None):
        self.url = url or settings.MCP_INTERNAL_URL
        self.token = issue_token(user)

    def list_tools(self) -> list[ToolSpec]:
        listed = self._run(lambda client: client.list_tools())
        return [
            ToolSpec(
                name=tool.name,
                title=tool.title or tool.name,
                description=tool.description or "",
                input_schema=tool.input_schema,
                needs_confirmation=not (tool.annotations and tool.annotations.read_only_hint),
            )
            for tool in listed.tools
        ]

    def call_tool(self, name: str, arguments: dict[str, Any]) -> ToolOutcome:
        result = self._run(lambda client: client.call_tool(name, arguments))
        text = "\n".join(block.text for block in result.content if getattr(block, "type", None) == "text")
        return ToolOutcome(text=text or "(nessun risultato)", is_error=bool(result.is_error))

    def _run(self, operation):
        async def go():
            http = httpx2.AsyncClient(
                headers={"Authorization": f"Bearer {self.token}"}, timeout=TIMEOUT_SECONDS
            )
            async with Client(streamable_http_client(self.url, http_client=http)) as client:
                return await operation(client)

        try:
            return asyncio.run(go())
        except Exception as exc:
            raise GatewayError(f"Server MCP non raggiungibile su {self.url}: {exc}") from exc
