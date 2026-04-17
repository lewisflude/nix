_: {
  flake.modules.darwin.organize = _: {
    homebrew.brews = [ "organize-tool" ];
  };

  flake.modules.homeManager.organize =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv) isDarwin;
      configPath = "${config.home.homeDirectory}/.config/organize/config.yaml";
    in
    lib.mkIf isDarwin {
      xdg.configFile."organize/config.yaml".text = ''
        rules:
          - name: Move screenshots off the Desktop
            locations: ~/Desktop
            subfolders: false
            filters:
              - name:
                  startswith: Screenshot
              - extension:
                  - png
                  - jpg
                  - jpeg
            actions:
              - move:
                  dest: ~/Pictures/Screenshots/
                  on_conflict: rename_new

          - name: Trash old installers
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - dmg
                  - pkg
              - lastmodified:
                  days: 7
                  mode: older
            actions:
              - trash

          - name: Sort Downloads — PDFs and documents
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - pdf
                  - doc
                  - docx
                  - rtf
                  - txt
                  - md
            actions:
              - move:
                  dest: ~/Downloads/Documents/
                  on_conflict: rename_new

          - name: Sort Downloads — images
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - jpg
                  - jpeg
                  - png
                  - gif
                  - heic
                  - webp
                  - svg
                  - tiff
            actions:
              - move:
                  dest: ~/Downloads/Images/
                  on_conflict: rename_new

          - name: Sort Downloads — archives
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - zip
                  - tar
                  - gz
                  - bz2
                  - 7z
                  - rar
              - lastmodified:
                  days: 3
                  mode: older
            actions:
              - move:
                  dest: ~/Downloads/Archives/
                  on_conflict: rename_new

          - name: Sort Downloads — audio and video
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - mp3
                  - wav
                  - flac
                  - aiff
                  - mp4
                  - mov
                  - mkv
                  - webm
            actions:
              - move:
                  dest: ~/Downloads/Media/
                  on_conflict: rename_new

          - name: Sort Downloads — fonts
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - ttf
                  - otf
                  - woff
                  - woff2
                  - eot
            actions:
              - move:
                  dest: ~/Downloads/Fonts/
                  on_conflict: rename_new

          - name: Archive stale loose files
            locations: ~/Downloads
            subfolders: false
            targets: files
            filters:
              - lastmodified:
                  days: 14
                  mode: older
            actions:
              - move:
                  dest: "~/Downloads/Archive/{lastmodified.strftime('%Y-%m')}/"
                  on_conflict: rename_new
      '';

      launchd.agents.organize = {
        enable = true;
        config = {
          ProgramArguments = [
            "/opt/homebrew/bin/organize"
            "run"
            configPath
          ];
          StartCalendarInterval = [
            {
              Hour = 9;
              Minute = 0;
            }
          ];
          RunAtLoad = false;
          StandardOutPath = "/tmp/organize.log";
          StandardErrorPath = "/tmp/organize.err";
        };
      };
    };
}
