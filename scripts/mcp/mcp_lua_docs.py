from mcp.server import Server, stdio
from mcp import types
import anyio
import httpx
from bs4 import BeautifulSoup

server = Server(name="lua-docs", version="0.1")

@server.list_tools()
async def list_tools():
    return [
        types.Tool(
            name="lua_doc",
            description="Fetch Lua 5.4 manual section by anchor",
            inputSchema={
                "type": "object",
                "properties": {
                    "anchor": {
                        "type": "string",
                        "description": "Anchor id, e.g. 'pdf-print'"
                    }
                },
                "required": ["anchor"],
            },
        )
    ]

@server.call_tool()
async def call_tool(name, arguments):
    if name != "lua_doc":
        return [types.TextContent(type="text", text=f"Unknown tool {name}")]
    anchor = arguments.get("anchor", "")
    url = f"https://www.lua.org/manual/5.4/manual.html#{anchor}"
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
