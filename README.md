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
