{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkIf mkOption;
  cfg = config.services.mindwtr.web;
in {
  options.services.mindwtr.web = {
    enable = lib.mkEnableOption "serving the webapp for Mindwtr, a complete GTD task manager";
    package = lib.mkPackageOption pkgs "mindwtr-web" {
      default = null;
      example = lib.literalExpression ''
        inputs.mindwtr-flake.packages.x86_64-linux."mindwtr-web"
      '';
    };

    nginx = {
      enable = lib.mkOption {
        default = true;
        type = types.bool;
        description = ''
          Whether to enable serving the mindwtr webapp through `nginx`

          Note: This also adds the [recommended config](https://github.com/dongdongbh/Mindwtr/blob/c6d1341de247080696ee9792767152d458a8b03c/docker/app/nginx.conf) from upstream
        '';
      };

      listen = mkOption {
        type = types.listOf (types.attrsOf types.anything);
        default = [
          {
            addr = "127.0.0.1";
            port = 5173;
          }
        ];
        description = "default";
      };

      virtualHost = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.literalMd ''
          Host to serve the webapp under

          To change or override further nginx settings, use the following:
          ```
          services.nginx.virtualHosts."$\{config.services.mindwtr.web.nginx.virtualHost}" = {
            someSetting = true;
          }
          ```
        '';
        example = "mindwtr.example.com";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.package != null;
        message = ''
          Please set the mindwtr webapp package
        '';
      }
      {
        assertion =
          cfg.nginx.enable
          -> cfg.nginx.virtualHost != null;
        message = ''
          nginx is enabled, but there is no virtualHost defined.
        '';
      }
    ];
    services.nginx.virtualHosts."${cfg.nginx.virtualHost}" = {
      root = "${cfg.package}";
      inherit (cfg.nginx) listen;
      extraConfig = ''
        index index.html;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
      '';

      locations = {
        # Hashed build assets: cache forever, and a missing chunk must 404 so the
        # client can recover — never fall back to index.html (Safari then fails the
        # module import with "Importing a module script failed", and a service
        # worker could cache the HTML under the chunk URL).
        # Note: add_header in a location disables inheritance, so the security
        # headers are repeated here and below.
        "/assets/" = {
          extraConfig = ''
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header Cache-Control "public, max-age=31536000, immutable" always;
          '';
          tryFiles = "$uri =404";
        };

        # Everything else (index.html, sw.js, manifest, icons) must revalidate so a
        # redeployed image is picked up instead of serving stale chunk references.
        "/" = {
          extraConfig = ''
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header Cache-Control "no-cache" always;
          '';
          tryFiles = "$uri /index.html";
        };
      };
    };
  };
}
