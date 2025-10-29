from mcp.server import Server, stdio
from mcp import types
import anyio
import httpx
from bs4 import BeautifulSoup

server = Server(name="love2d-docs", version="0.1")

@server.list_tools()
async def list_tools():
    return [
        types.Tool(
            name="love2d_doc",
            description="Fetch Love2D documentation page by slug",
            inputSchema={
                "type": "object",
                "properties": {
                    "slug": {
                        "type": "string",
                        "description": "Page slug, e.g. 'love.graphics'"
                    }
                },
                "required": ["slug"],
            },
        )
    ]

@server.call_tool()
async def call_tool(name, arguments):
    if name != "love2d_doc":
        return [types.TextContent(type="text", text=f"Unknown tool {name}")]
    slug = arguments.get("slug", "")
    url = f"https://love2d.org/wiki/{slug}"
    async with httpx.AsyncClient() as client:
        resp = await client.get(url)
    if resp.status_code != 200:
        return [types.TextContent(type="text", text=f"Error fetching {url}: {resp.status_code}")]
    soup = BeautifulSoup(resp.text, "html.parser")
    text = soup.get_text("\n")
    return [types.TextContent(type="text", text=text)]

async def main():
    opts = server.create_initialization_options()
    async with stdio.stdio_server() as (read, write):
        await server.run(read, write, opts)

if __name__ == "__main__":
    anyio.run(main)
