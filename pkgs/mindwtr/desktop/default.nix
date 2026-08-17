{
  fetchFromGitHub,
  bun2nix,
  cargo-tauri,
  webkitgtk_4_1,
  rustPlatform,
  pkg-config,
  perl,
  alsa-lib,
  cmake,
  libayatana-appindicator,
  gtk3,
  wrapGAppsHook3,
  nix-update-script,
  lib,
  _experimental-update-script-combinators,
  writeShellApplication,
  nix,
  statix,
  git,
}: let
  cargoRoot = "apps/desktop/src-tauri";
  version = "1.2.1";
  src = fetchFromGitHub {
    owner = "dongdongbh";
    repo = "mindwtr";
    tag = "v${version}";
    hash = "sha256-VSe+Tvs/7F6S/SYNClIgLO1GQ88t84WP8z7ZXdn7iiI=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "mindwtr";
    inherit version src;
    cargoHash = "sha256-dJfy8K9w+kpDkyV63dHoNT6zdFuYfxcdQ2wbxDldIG0=";

    passthru = {
      updateScript = _experimental-update-script-combinators.sequence [
        (nix-update-script {
          extraArgs = [
            "--flake"
          ];
        })
        (lib.getExe (writeShellApplication {
          name = "bun2nix-update-deps";
          runtimeInputs = [
            bun2nix
            nix
            statix
          ];
          text = ''
            [[ -f ./flake.nix ]]
            cd ${src}
            bun2nix | grep -Ev '^\s*?".*?" = copyPathToStore ./.*?;$' > "$OLDPWD/pkgs/mindwtr/bun.nix"
          '';
        }))
        (nix-update-script {
          extraArgs = [
            "--flake"
            "--commit"
          ];
        })
        (lib.getExe (writeShellApplication {
          name = "commit-bun-lockfile";
          runtimeInputs = [
            git
          ];
          text = ''
            git add pkgs/mindwtr/bun.nix
            git commit --amend --no-edit
          '';
        }))
      ];
    };

    nativeBuildInputs = [
      bun2nix.hook
      cargo-tauri.hook
      rustPlatform.bindgenHook # whisper-rs-sys
      cmake # ^
      perl # openssl
      pkg-config
      wrapGAppsHook3
    ];

    buildInputs = [
      alsa-lib # alsa-sys
      webkitgtk_4_1
      gtk3
      libayatana-appindicator #libappindicator-sys
    ];

    # Rename the `.desktop` file to make sure the app ID links correctly
    postFixup = ''
      patchelf --add-needed ${libayatana-appindicator}/lib/libayatana-appindicator3.so $out/bin/.mindwtr-wrapped
      mv $out/share/applications/Mindwtr.desktop $out/share/applications/mindwtr.desktop
    '';
    bunDeps = bun2nix.fetchBunDeps {
      bunNix = ../bun.nix;
    };
    dontUseBunBuild = true;
    dontUseBunCheck = true;
    dontUseBunInstall = true;

    inherit cargoRoot;
    buildAndTestSubdir = cargoRoot;

    meta = {
      maintainers = [lib.maintainers.therealgramdalf];
      homepage = "https://mindwtr.app/";
      description = "Desktop app for Mindwtr, a complete Getting Things Done (GTD) productivity system - Mind Like Water";
      license = lib.licenses.agpl3Only;
    };
  }
