{
  description = "Third party flake providing Mindwtr desktop, cloud sync server, and webapp";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    bun2nix-baseline = {
      url = "github:therealgramdalf/bun2nix-baseline";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    bun2nix-baseline,
    ...
  }: let
    x86pkgs = nixpkgs.legacyPackages.x86_64-linux;
    x86bun2nix = bun2nix-baseline.packages.x86_64-linux.default;
  in {
    formatter.x86_64-linux = x86pkgs.alejandra;

    packages.x86_64-linux = {
      default = self.packages.x86_64-linux.hello;
      "mindwtr-web" = x86pkgs.callPackage ./pkgs/mindwtr/web {
        bun2nix = x86bun2nix;
      };
      "mindwtr-desktop" = x86pkgs.callPackage ./pkgs/mindwtr/desktop {
        bun2nix = x86bun2nix;
      };
      "mindwtr-cloud" = x86pkgs.callPackage ./pkgs/mindwtr/cloud {
        bun2nix = x86bun2nix;
      };
    };
  };
}
