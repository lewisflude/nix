#!/usr/bin/env python3
"""
Love2D API Documentation MCP Server

Provides access to Love2D API documentation and examples through MCP.
"""

from dataclasses import dataclass
from typing import Any, Dict, List

from mcp import types
from mcp.server import Server, stdio
import anyio

# Love2D API categories and their documentation URLs
LOVE2D_API_BASE = "https://love2d.org/wiki"
LOVE2D_MODULES = {
    "love.audio": "Provides an interface to output audio",
    "love.data": "Provides data transformation functions",
    "love.event": "Manages events for the game loop",
    "love.filesystem": "Provides an interface to the user's filesystem",
    "love.font": "Allows working with fonts",
    "love.graphics": "Drawing of shapes, images, text, and other drawable objects to the screen",
    "love.image": "Provides an interface to decode and manipulate encoded image data",
    "love.joystick": "Provides an interface to connected joysticks",
    "love.keyboard": "Provides an interface to the user's keyboard",
    "love.math": "Provides mathematical functions",
    "love.mouse": "Provides an interface to the user's mouse",
    "love.physics": "2D physics simulation using Box2D",
    "love.sound": "Contains raw audio data",
    "love.system": "Provides access to information about the user's system",
    "love.thread": "Allows multithreading",
    "love.timer": "Provides timing functionality",
    "love.touch": "Provides an interface to touch screens",
    "love.video": "Can play back video files",
    "love.window": "Provides interface for modifying window properties"
}

@dataclass
class Love2DFunction:
    name: str
    module: str
    description: str
    syntax: str
    parameters: List[str]
    returns: str
    examples: List[str]

class Love2DDocumentationServer:
    def __init__(self):
        self.functions_cache: Dict[str, Love2DFunction] = {}
        self.loaded = False
    
    def load_api_data(self):
        """Load Love2D API data (in a real implementation, this would scrape or use cached data)"""
        if self.loaded:
            return
        
        # Sample Love2D functions for demonstration
        sample_functions = [
            Love2DFunction(
                name="love.graphics.print",
                module="love.graphics",
                description="Draws text on screen at specified position",
                syntax="love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)",
                parameters=[
                    "text (string): The text to draw",
                    "x (number): The x-coordinate",
                    "y (number): The y-coordinate",
                    "r (number, optional): Rotation in radians",
                    "sx (number, optional): Scale factor (x-axis)",
                    "sy (number, optional): Scale factor (y-axis)",
                    "ox (number, optional): Origin offset (x-axis)",
                    "oy (number, optional): Origin offset (y-axis)",
                    "kx (number, optional): Shearing factor (x-axis)",
                    "ky (number, optional): Shearing factor (y-axis)"
                ],
                returns="None",
                examples=[
                    'love.graphics.print("Hello World", 400, 300)',
                    'love.graphics.print("Rotated text", 400, 300, math.pi/4)'
                ]
            ),
            Love2DFunction(
                name="love.graphics.rectangle",
                module="love.graphics",
                description="Draws a rectangle",
                syntax="love.graphics.rectangle(mode, x, y, width, height)",
                parameters=[
                    "mode (DrawMode): How to draw the rectangle ('fill' or 'line')",
                    "x (number): The x-coordinate of the top-left corner",
                    "y (number): The y-coordinate of the top-left corner", 
                    "width (number): Width of the rectangle",
                    "height (number): Height of the rectangle"
                ],
                returns="None",
                examples=[
                    'love.graphics.rectangle("fill", 100, 100, 200, 150)',
                    'love.graphics.rectangle("line", 50, 50, 100, 100)'
                ]
            ),
            Love2DFunction(
                name="love.update",
                module="love",
                description="Callback function used to update the state of the game every frame",
                syntax="function love.update(dt) end",
                parameters=[
                    "dt (number): Time since the last update in seconds"
                ],
                returns="None",
                examples=[
                    "function love.update(dt)\n    player.x = player.x + player.speed * dt\nend"
                ]
            ),
            Love2DFunction(
                name="love.draw",
                module="love",
                description="Callback function used to draw on the screen every frame",
                syntax="function love.draw() end",
                parameters=[],
                returns="None",
                examples=[
                    "function love.draw()\n    love.graphics.print('Hello World!', 400, 300)\nend"
                ]
            ),
            Love2DFunction(
                name="love.load",
                module="love",
                description="This function is called exactly once at the beginning of the game",
                syntax="function love.load() end",
                parameters=[],
                returns="None",
                examples=[
                    "function love.load()\n    player = { x = 100, y = 100, speed = 200 }\nend"
                ]
            )
        ]
        
        for func in sample_functions:
            self.functions_cache[func.name] = func
        
        self.loaded = True

server = Server(name="love2d-api", version="0.1")
docs = Love2DDocumentationServer()

@server.list_tools()
async def list_tools() -> List[types.Tool]:
    """List available Love2D API tools"""
    return [
        types.Tool(
            name="search_love2d_api",
            description="Search Love2D API functions and documentation",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query for Love2D functions or modules"
                    },
                    "module": {
                        "type": "string",
                        "description": "Optional: Filter by specific Love2D module",
                        "enum": list(LOVE2D_MODULES.keys())
                    }
                },
                "required": ["query"]
            }
        ),
        types.Tool(
            name="get_love2d_function",
            description="Get detailed documentation for a specific Love2D function",
            inputSchema={
                "type": "object", 
                "properties": {
                    "function_name": {
                        "type": "string",
                        "description": "Name of the Love2D function (e.g., 'love.graphics.print')"
                    }
                },
                "required": ["function_name"]
            }
        ),
        types.Tool(
            name="list_love2d_modules",
            description="List all Love2D modules with descriptions",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        types.Tool(
            name="generate_love2d_template",
            description="Generate basic Love2D project template",
            inputSchema={
                "type": "object",
                "properties": {
                    "template_type": {
                        "type": "string",
                        "description": "Type of template to generate",
                        "enum": ["basic", "platformer", "top-down", "puzzle"]
                    }
                },
                "required": ["template_type"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> List[types.TextContent]:
    """Handle tool calls"""
    docs.load_api_data()
    
    if name == "search_love2d_api":
        query = arguments["query"].lower()
        module_filter = arguments.get("module")
        
        results = []
        for func_name, func in docs.functions_cache.items():
            if module_filter and func.module != module_filter:
                continue
                
            if (query in func_name.lower() or 
                query in func.description.lower() or
                query in func.module.lower()):
                results.append(f"**{func.name}** ({func.module})\n{func.description}\n")
        
        if not results:
            return [types.TextContent(
                type="text",
                text=f"No Love2D functions found matching '{query}'"
            )]
        
        return [types.TextContent(
            type="text", 
            text=f"Found {len(results)} Love2D functions:\n\n" + "\n".join(results)
        )]
    
    elif name == "get_love2d_function":
        func_name = arguments["function_name"]
        
        if func_name not in docs.functions_cache:
            return [types.TextContent(
                type="text",
                text=f"Function '{func_name}' not found in Love2D API"
            )]
        
        func = docs.functions_cache[func_name]
        
        doc_text = f"""# {func.name}

**Module:** {func.module}

**Description:** {func.description}

**Syntax:**
```lua
{func.syntax}
```

**Parameters:**
"""
        for param in func.parameters:
            doc_text += f"- {param}\n"
        
        doc_text += f"\n**Returns:** {func.returns}\n\n**Examples:**\n"
        for example in func.examples:
            doc_text += f"```lua\n{example}\n```\n\n"
        
        return [types.TextContent(type="text", text=doc_text)]
    
    elif name == "list_love2d_modules":
        module_list = "# Love2D Modules\n\n"
        for module, description in LOVE2D_MODULES.items():
            module_list += f"**{module}**: {description}\n\n"
        
        return [types.TextContent(type="text", text=module_list)]
    
    elif name == "generate_love2d_template":
        template_type = arguments["template_type"]
        
        templates = {
            "basic": '''-- Basic Love2D Template
function love.load()
    -- Initialize game variables
    player = {
        x = 400,
        y = 300,
        speed = 200
    }
end

function love.update(dt)
    -- Update game logic
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    elseif love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end
    
    if love.keyboard.isDown("up") then
        player.y = player.y - player.speed * dt
    elseif love.keyboard.isDown("down") then
        player.y = player.y + player.speed * dt
    end
end

function love.draw()
    -- Draw everything
    love.graphics.circle("fill", player.x, player.y, 20)
end''',
            
            "platformer": '''-- Platformer Love2D Template
function love.load()
    player = {
        x = 100,
        y = 400,
        width = 32,
        height = 32,
        vx = 0,
        vy = 0,
        speed = 200,
        jumpPower = 400,
        onGround = false
    }
    
    gravity = 800
    ground = love.graphics.getHeight() - 100
end

function love.update(dt)
    -- Horizontal movement
    if love.keyboard.isDown("left") then
        player.vx = -player.speed
    elseif love.keyboard.isDown("right") then
        player.vx = player.speed
    else
        player.vx = 0
    end
    
    -- Jumping
    if love.keyboard.isDown("space") and player.onGround then
        player.vy = -player.jumpPower
        player.onGround = false
    end
    
    -- Apply gravity
    player.vy = player.vy + gravity * dt
    
    -- Update position
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    
    -- Ground collision
    if player.y + player.height >= ground then
        player.y = ground - player.height
        player.vy = 0
        player.onGround = true
    end
end

function love.draw()
    -- Draw ground
    love.graphics.rectangle("fill", 0, ground, love.graphics.getWidth(), 100)
    
    -- Draw player
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
end'''
        }
        
        if template_type not in templates:
            return [types.TextContent(
                type="text",
                text=f"Template type '{template_type}' not available. Available types: {list(templates.keys())}"
            )]
        
        return [types.TextContent(
            type="text",
            text=f"# Love2D {template_type.capitalize()} Template\n\n```lua\n{templates[template_type]}\n```"
        )]
    
    return [types.TextContent(type="text", text=f"Unknown tool: {name}")]


async def main():
    """Main entry point for the MCP server"""
    opts = server.create_initialization_options()
    async with stdio.stdio_server() as (read, write):
        await server.run(read, write, opts)


if __name__ == "__main__":
    anyio.run(main)
