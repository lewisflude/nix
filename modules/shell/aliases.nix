# Shell aliases.
#
# Split out from zsh.nix because this is churning data, not behaviour: nothing
# here participates in the .zshrc ordering contract.
_: {
  flake.modules.homeManager.shell =
    { pkgs, ... }:
    {
      programs.zsh.shellAliases = {
        # System rebuild
        switch = if pkgs.stdenv.isLinux then "nh os switch" else "nh darwin switch";

        # Core utilities.
        #
        # ls / ll / lt come from programs.eza.enableZshIntegration and are NOT
        # repeated here: zsh chains alias expansion, so they resolve through
        # eza's generated `eza` alias and pick up icons/git/colors. Only `l`
        # (eza defines no such alias) and `la` (eza's is `-a`, we want `-la`)
        # need defining.
        #
        # `find` is deliberately NOT aliased to fd: fd's CLI is incompatible, so
        # `find . -name '*.nix'` fails confusingly, and the habit does not
        # transfer to any machine without this config.
        l = "eza -l";
        la = "eza -la";
        edit = "sudo -e";
        cat = "bat";
        top = "btop";

        # Directory navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        d = "dirs -v";
        po = "popd";
        pu = "pushd";

        # Git shortcuts
        g = "git";
        gs = "git status";
        gd = "git diff";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";
        gco = "git checkout";
        gb = "git branch";
        glog = "git log --oneline --graph --decorate";

        # Network utilities
        ports = "ss -tulanp || netstat -tulanp";
        myip = "curl -s ifconfig.me";

        # Nix commands (with glob disabling for '#')
        nix = "noglob nix";
        nix-build = "noglob nix build";
        nix-run = "noglob nix run";
        nix-develop = "noglob nix develop";
        nix-shell = "noglob nix-shell";
        nix-search = "nh search";
        nix-info = "nix-info -m";
        nix-size = "du -sh /nix/store";
        nix-update-lock = "nix flake update --flake ~/.config/nix";

        # nh (Nix Helper) commands
        nh-os = "nh os";
        nh-home = "nh home";
        nh-darwin = "nh darwin";
        nh-clean = "nh clean all $NH_CLEAN_ARGS";
        nh-clean-old = "nh clean all --keep-since 7d --keep 5";
        nh-clean-aggressive = "nh clean all --keep-since 1d --keep 1";
        nh-list = "nh os list";
        nh-rollback = "nh os rollback";
        nh-diff = "nh os diff";
        nh-build = "nh os build";
        nh-build-dry = "nh os build --dry";
        nh-switch-dry = "nh os switch --dry";
        nh-check-all = "nix flake check --show-trace ~/.config/nix";
        nh-eval-system = "sudo nixos-rebuild build --show-trace --flake ~/.config/nix";

        # File listing shortcuts
        lsh = "eza -la .*";
        lsz = "eza -la ***.{js,ts,jsx,tsx,py,go,rs,c,cpp,h,hpp}";
        lsconfig = "eza -la **/*.{json,yaml,yml,toml,ini,conf,cfg}";

        # Zellij. zjls and zjk are functions in zsh/functions.zsh (they format
        # output and support `zjk all`); aliases of the same name would shadow
        # them at parse time, so only the ones without functions live here.
        zja = "zellij attach";
        zjd = "zellij delete-session";

        # Editor
        zed = "zeditor";
      };

      programs.zsh.shellGlobalAliases = {
        G = "| grep";
        GI = "| grep -i";
        L = "| less";
        H = "| head";
        T = "| tail";
        J = "| jq";
        NUL = ">/dev/null 2>&1";
        NE = "2>/dev/null";
      };
    };
}
