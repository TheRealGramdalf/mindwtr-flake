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
  };
  bunInstallFlags = [
    "--linker=hoisted"
  ];

  buildPhase = ''
    bun run desktop:web:build
  '';

  installPhase = ''
    mkdir -p $out

    cp -R --reflink=auto ./apps/desktop/dist/. $out
  '';

  meta = {
    maintainers = [lib.maintainers.therealgramdalf];
    homepage = "https://mindwtr.app/";
    description = "Progressive web app for Mindwtr, a complete Getting Things Done (GTD) productivity system - Mind Like Water";
    license = lib.licenses.agpl3Only;
  };
}
