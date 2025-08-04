{
  pkgs,
  config,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    uv
    python3
  ];

  home.file."bin/kagi-mcp-wrapper".text = ''
    #!/usr/bin/env bash
    export KAGI_API_KEY="$(cat ${config.sops.secrets.KAGI_API_KEY.path})"
    exec ${pkgs.uv}/bin/uvx kagimcp "$@"
  '';
  home.file."bin/kagi-mcp-wrapper".executable = true;

  services.mcp.enable = true;
  services.mcp.targets = {
    cursor = {
      directory = "${config.home.homeDirectory}/.cursor";
      fileName = "mcp.json";
    };
    claude-code = {
      directory = "${config.home.homeDirectory}/.config/claude";
      fileName = "claude_desktop_config.json";
    };
  };
  # Activation script to register MCP servers with Claude Code
  home.activation.setupClaudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] (let
    cfg = config.services.mcp;
    
    # Generate claude mcp add commands for each configured server
    mcpAddCommands = lib.concatStringsSep "\n        " (
      lib.mapAttrsToList (name: serverCfg:
        let
          # Build the command and arguments separately
          command = lib.escapeShellArg serverCfg.command;
          args = lib.concatStringsSep " " (map lib.escapeShellArg serverCfg.args);
          # Build environment variable exports
          envVars = lib.concatStringsSep " " (
            lib.mapAttrsToList (key: value: 
              "export ${lib.escapeShellArg key}=${lib.escapeShellArg value};"
            ) serverCfg.env
          );
        in
        ''${envVars} claude mcp add ${lib.escapeShellArg name} -s user ${command} -- ${args} || echo "Failed to add ${name} server"''
      ) cfg.servers
    );
  in
  ''
    echo "Starting Claude MCP setup activation script..."
    echo "PATH: $PATH"
    echo "USER: $USER"
    echo "HOME: $HOME"
    
    # Explicitly add common paths where claude might be
    export PATH="${pkgs.coreutils}/bin:$PATH:/etc/profiles/per-user/$USER/bin:/home/$USER/.nix-profile/bin"
    
    if command -v claude >/dev/null 2>&1; then
      echo "Claude CLI found at: $(which claude)"
      echo "Registering MCP servers with Claude Code..."
      
      # Remove existing servers first (ignore errors)
      ${pkgs.findutils}/bin/find ~/.config/claude -name "*.json" -delete 2>/dev/null || true
      
      # Add each configured server
      $DRY_RUN_CMD ${pkgs.writeShellScript "setup-claude-mcp" ''
        # Ensure PATH includes claude
        export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
        
        echo "Removing existing MCP servers..."
        # Remove existing servers in all scopes (ignore errors)
        for server in ${lib.concatStringsSep " " (lib.mapAttrsToList (name: _: lib.escapeShellArg name) cfg.servers)}; do
          /etc/profiles/per-user/$USER/bin/claude mcp remove "$server" -s user 2>/dev/null || true
          /etc/profiles/per-user/$USER/bin/claude mcp remove "$server" -s project 2>/dev/null || true
          /etc/profiles/per-user/$USER/bin/claude mcp remove "$server" 2>/dev/null || true
        done
        
        echo "Running MCP server registration commands..."
        ${mcpAddCommands}
        
        echo "Checking final server list:"
        /etc/profiles/per-user/$USER/bin/claude mcp list || echo "Failed to list servers"
        
        echo "Claude MCP server registration complete (nixos)"
      ''}
    else
      echo "Claude CLI not found in PATH: $PATH"
      echo "Checking common locations:"
      ls -la /etc/profiles/per-user/$USER/bin/claude 2>/dev/null || echo "Not found in per-user profile"
      ls -la /home/$USER/.nix-profile/bin/claude 2>/dev/null || echo "Not found in user profile"
    fi
    
    echo "Claude MCP setup activation script finished"
  '');

  services.mcp.servers = {
    kagi = {
      command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
      args = [ ];
      port = 11431;
      env = {
        KAGI_API_KEY = config.sops.secrets.KAGI_API_KEY.path;
      };
    };
    fetch = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-server-fetch" ];
      port = 11432;
    };
    git = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-server-git" ];
      port = 11433;
    };
    github = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-github"
      ];
      port = 11434;
    };
    nx = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "nx-mcp@latest"
        "${config.home.homeDirectory}/Code/dex-web"
      ];
      port = 11435;
    };
    memory = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
      port = 11436;
    };
    sequential-thinking = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
      port = 11437;
    };
    love2d-api = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--python"
        "${pkgs.python3}/bin/python3"
        "--with"
        "mcp"
        "--with"
        "requests"
        "python"
        "${config.home.homeDirectory}/.config/nix/mcp-servers/love2d-api.py"
      ];
      port = 11440;
    };
    love2d-filesystem = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        "${config.home.homeDirectory}/Code/love2d-projects"
        "${config.home.homeDirectory}/.local/share/love"
      ];
      port = 11441;
    };
    general-filesystem = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        "${config.home.homeDirectory}/Code"
        "${config.home.homeDirectory}/.config"
        "${config.home.homeDirectory}/Documents"
      ];
      port = 11442;
    };

    love2d-docs = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--with" "mcp"
        "--with" "httpx"
        "--with" "beautifulsoup4"
        "python" "${../../scripts/mcp_love2d_docs.py}"
      ];
      port = 11440;
    };
    lua-docs = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--with" "mcp"
        "--with" "httpx"
        "--with" "beautifulsoup4"
        "python" "${../../scripts/mcp_lua_docs.py}"
      ];
      port = 11441;
    };

  };
}
