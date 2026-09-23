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
  lib,
}: let
  cargoRoot = "apps/desktop/src-tauri";
  version = "1.3.2";
  src = fetchFromGitHub {
    owner = "dongdongbh";
    repo = "mindwtr";
    tag = "v${version}";
    hash = "sha256-4JSPzTiZUGJvXCSJSxEm9lU7qp51Xgj/rsEz/9Nr8L4=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "mindwtr";
    inherit version src;
    cargoHash = "sha256-7msYp78ucHk0xVNscM1QhnWGXZXc66AgTF36osEtrhE=";

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
      overrides = bun2nix.patchedDependenciesToOverrides {
        patchedDependencies = lib.mapAttrs (_: path: (src + "/${path}")) (
          (lib.importJSON (src + /package.json)).patchedDependencies
        );
      };
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
