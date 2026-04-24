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

          - name: Move screen recordings off the Desktop
            locations: ~/Desktop
            subfolders: false
            filters:
              - name:
                  startswith: "Screen Recording"
              - extension:
                  - mov
                  - mp4
            actions:
              - move:
                  dest: ~/Movies/Screen Recordings/
                  on_conflict: rename_new

          - name: Sweep stale Desktop images
            locations: ~/Desktop
            subfolders: false
            filters:
              - extension:
                  - png
                  - jpg
                  - jpeg
                  - heic
                  - avif
              - lastmodified:
                  days: 7
                  mode: older
            actions:
              - move:
                  dest: ~/Pictures/Inbox/
                  on_conflict: rename_new

          - name: Sort receipts into Documents/Receipts
            locations: ~/Documents
            subfolders: false
            filters:
              - name:
                  startswith: Receipt
              - extension:
                  - docx
                  - pdf
                  - rtf
            actions:
              - move:
                  dest: ~/Documents/Receipts/
                  on_conflict: rename_new

          - name: Sweep loose images from Documents root
            locations: ~/Documents
            subfolders: false
            filters:
              - extension:
                  - png
                  - jpg
                  - jpeg
                  - svg
              - lastmodified:
                  days: 14
                  mode: older
            actions:
              - move:
                  dest: ~/Pictures/Inbox/
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

          - name: Trash stale torrent files
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension: torrent
              - lastmodified:
                  days: 2
                  mode: older
            actions:
              - trash

          - name: Sort Downloads — Blender models
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - blend
                  - blend2
                  - fbx
                  - obj
                  - stl
                  - gltf
                  - glb
                  - usd
                  - usdc
                  - usdz
                  - ply
                  - dae
            actions:
              - move:
                  dest: ~/3D/incoming/models/
                  on_conflict: rename_new

          - name: Sort Downloads — HDRIs
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - hdr
                  - exr
            actions:
              - move:
                  dest: ~/3D/incoming/hdri/
                  on_conflict: rename_new

          - name: Sort Downloads — Ableton files
            locations: ~/Downloads
            subfolders: false
            filters:
              - extension:
                  - als
                  - alp
                  - adg
                  - adv
                  - alc
                  - agr
                  - amxd
            actions:
              - move:
                  dest: ~/Music/Ableton/Incoming/
                  on_conflict: rename_new

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

          - name: Install downloaded fonts
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
                  dest: ~/Library/Fonts/
                  on_conflict: skip

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
