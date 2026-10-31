import uvicorn
from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from apps.assistant.mcp.server import build_app


class Command(BaseCommand):
    help = "Avvia il server MCP (Streamable HTTP su /mcp) come servizio a sé."

    def add_arguments(self, parser):
        parser.add_argument("--host", default="0.0.0.0")
        parser.add_argument("--port", type=int, default=8001)

    def handle(self, *args, host: str, port: int, **options):
        if not settings.MCP_TOKEN or not settings.MCP_USERNAME:
            raise CommandError("Imposta MCP_TOKEN e MCP_USERNAME nel .env")
        uvicorn.run(build_app(), host=host, port=port, log_level="info", proxy_headers=False)
