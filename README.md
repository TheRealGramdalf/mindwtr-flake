> [!WARNING] 
> This flake is currently considered **experimental**. I cannot currently guarantee stability.
> 
> That being said, I personally use Mindwtr on a daily basis, and will do my best to keep things functional. See below for an in-depth explanation.

## Outputs

This flake currently provides the following packages:
- `mindwtr`: The mindwtr desktop application. This is the default package, which can be built and run with `nix run github:therealgramdalf/mindwtr-flake`
- `mindwtr-web`: Static webapp, hostable with a web server such as `nginx` or `caddy`. Configurable through the included `nixosModule`
- `mindwtr-cloud`: Wrapper script for the self hostable mindwtr sync server, made with `bun2nix.writeBunApplication`. Configurable through the included `nixosModule`

`nixosModules.default` provides the following:
- `services.mindwtr.web`: Serves the webapp through a webserver backend. Currently only `nginx` is available
- `services.mindwtr.cloud`: Configures a systemd service for the cloud sync server. It is recommended to serve this through a proxy to provide HTTPS

## Stability

All three packages can be considered generally stable. There should be few (if any) bugs exclusive to the Nix packages. If there are, please let me know.
The packages are currently only made available for `x86_64-linux`, but should be adaptable to other platforms. Please open an issue if you need this.

The NixOS modules should be considered functional, but not perfect. There are currently no guarantees that the options will remain the same or backwards compatibility will be maintained. This is a concious desicion so that I can release the module and make it available to others, without having to lock down a perfect implementation the first time around or committing to support certain options long term. In the worst case, this should only require manually renaming certain options or moving/fixing permissions of server data.

## Usage

Below is a minimal example of how to use this flake:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    mindwtr-flake = {
      url = "github:therealgramdalf/mindwtr-flake";
      inputs.nixpkgs.follows = "nixpkgs"; # Rename this if your nixpkgs input isn't named `nixpkgs`
    };
  };

  # In this context, `inputs @` essentially means "create an attribute set containing all flake inputs". This way, you can just
  # use `...` to accept any arguments, rather than adding each extra input like `outputs = {nixpkgs, mindwtr-flake}:`,
  # and manually adding `mindwtr-flake` to `specialArgs`
  outputs = inputs @ {nixpkgs, ...}: {
    nixosConfigurations = {
      "your-systems-hostname" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          # Pass `inputs` to your configuration, or it won't be accessible
          inherit inputs;
        };
        modules = [
          # Import the NixOS modules (`services.mindwtr.*`) to make them available if needed
          # You can remove this if you aren't using them to speed up evaluation slightly
          inputs.mindwtr-flake.nixosModules.default
          ./configuration.nix
        ];
      };
    };
  };
}
```

To use the packages in e.g. your `configuration.nix`:

```nix
# Bring the `inputs` specialArg into scope
{inputs, ...}: {
  environment.systemPackages = [
    # The quotes aren't necessary, but I like to use them to highlight important
    # parts of code with syntax highlighting
    inputs."mindwtr-flake".packages.x86_64-linux."mindwtr"
  ];
}
```

## Updating

> [!WARNING] 
> The current update script implementation means that the `bun.nix` file won't be updated correctly. For now, simply running the update command twice is a technically functional workaround. A better solution is still in the works.

Updating the package versions (including the `cargoHash` and `bun.nix` lock file) is accomplished via `nix-update` and a crude helper script,
and can be invoked with the following: 

```sh
nix-update --flake mindwtr -u
```

`nix-update` must be available in `$PATH`, and you currently must be at the project root (the directory containing this file).