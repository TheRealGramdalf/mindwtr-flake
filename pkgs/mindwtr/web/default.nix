{
  bun2nix,
  stdenv,
  version,
  src,
  lib,
}:
stdenv.mkDerivation {
  pname = "mindwtr-web";
  inherit version src;

  nativeBuildInputs = [
    bun2nix.hook
  ];

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ../bun.nix;
    overrides = bun2nix.patchedDependenciesToOverrides {
      patchedDependencies = lib.mapAttrs (_: path: (src + "/${path}")) (
        (lib.importJSON (src + /package.json)).patchedDependencies
      );
    };
  };
  bunInstallFlags = [
    "--linker=hoisted"
  ];

  buildPhase = ''
    mkdir -p $out
    bun run desktop:web:build -- --outDir $out
  '';

  dontInstall = true;

  meta = {
    maintainers = [lib.maintainers.therealgramdalf];
    homepage = "https://mindwtr.app/";
    description = "Progressive web app for Mindwtr, a complete Getting Things Done (GTD) productivity system - Mind Like Water";
    license = lib.licenses.agpl3Only;
  };
}
