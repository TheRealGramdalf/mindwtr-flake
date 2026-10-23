{
  fetchFromGitHub,
  bun2nix,
  cargo-tauri,
  webkitgtk_4_1,
  rustPlatform,
  pkg-config,
  alsa-lib,
  cmake,
  libayatana-appindicator,
  gtk3,
  wrapGAppsHook3,
  lib,
  gsettings-desktop-schemas,
  glib-networking,
  openssl,
  glib,
  desktop-file-utils,
  xdg-utils,
  fetchpatch2,
}: let
  cargoRoot = "apps/desktop/src-tauri";
  version = "1.3.6";
  src = fetchFromGitHub {
    owner = "dongdongbh";
    repo = "mindwtr";
    tag = "v${version}";
    hash = "sha256-xqbom//GBoVAAtT032XA7QgVwxGx9v/swPa69fmYNIA=";
  };
in
  rustPlatform.buildRustPackage {
    pname = "mindwtr";
    inherit version src;
    cargoHash = "sha256-Ikc4xAyFxLBbjLD13p9yOh1dQIIoEtCwRPSBG6nQac4=";

    # Patches for unreleased fixes. Fetch by appending `.patch`/`.diff` to a commit/PR and passing the URL through `nurl`
    # You will likely need to `excludes = ["docs/*"];` if the patch does not apply. When doing so, empty the `hash` argument to recompute the changes.
    patches = [
    ];

    # Upstream issues, which include guidance given, can be found here: https://github.com/dongdongbh/Mindwtr/issues/996
    env.OPENSSL_NO_VENDOR = "1";

    nativeBuildInputs = [
      bun2nix.hook
      cargo-tauri.hook
      rustPlatform.bindgenHook # whisper-rs-sys
      cmake # ^
      pkg-config
      wrapGAppsHook3
    ];

    buildInputs = [
      alsa-lib # alsa-sys
      webkitgtk_4_1
      gtk3
      libayatana-appindicator #libappindicator-sys
      gsettings-desktop-schemas
      glib-networking
      openssl
      # wrapper
      glib
      xdg-utils
      desktop-file-utils
    ];

    preFixup = ''
      gappsWrapperArgs+=(
        # gsettings & gdbus are needed for theme detection
        --prefix PATH : "${lib.makeBinPath [glib xdg-utils desktop-file-utils]}"
      )
    '';

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
    # cmake is needed by whisper-rs-sys but there is no root CMakeLists.txt.
    dontUseCmakeConfigure = true;
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
