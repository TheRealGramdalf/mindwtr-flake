{
  bun2nix,
  version,
  src,
  lib,
}:
bun2nix.writeBunApplication {
  pname = "mindwtr-cloud";
  inherit version src;

  dontUseBunBuild = true;
  startScript = ''
    bun run --filter mindwtr-cloud dev
  '';

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ../bun.nix;
  };
  bunInstallFlags = [
    "--linker=hoisted"
  ];

  meta = {
    maintainers = [lib.maintainers.therealgramdalf];
    homepage = "https://mindwtr.app/";
    description = "Cloud sync server for Mindwtr, a complete Getting Things Done (GTD) productivity system - Mind Like Water";
    license = lib.licenses.agpl3Only;
  };
}
