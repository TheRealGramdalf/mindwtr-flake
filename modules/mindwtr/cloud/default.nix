{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkIf mkOption;
  inherit (lib.types) nullOr str;
  cfg = config.services.mindwtr.cloud;
in {
  options.services.mindwtr.cloud = {
    enable = lib.mkEnableOption "the self-hosted sync server for Mindwtr, a complete GTD task manager";

    package = lib.mkPackageOption pkgs "mindwtr-cloud" {
      default = null;
      example = lib.literalExpression ''
        inputs.mindwtr-flake.packages.x86_64-linux."mindwtr-cloud"
      '';
    };

    user = mkOption {
      default = "mindwtr-cloud";
      type = str;
      description = ''
        User under which mindwtr-cloud runs.

        ::: {.note}
        If left as the default value this user will automatically be created
        on system activation, otherwise you are responsible for
        ensuring the user exists before the mindwtr-cloud service starts.
        :::
      '';
    };

    group = mkOption {
      default = "mindwtr-cloud";
      type = str;
      description = ''
        Primary group under which mindwtr-cloud runs.

        ::: {.note}
        If left as the default value this group will automatically be created
        on system activation, otherwise you are responsible for
        ensuring the group exists before the mindwtr-cloud service starts.
        :::
      '';
    };

    port = mkOption {
      type = types.port;
      description = "The port to listen on, passed as `--port`";
      default = 5173;
    };

    environment = mkOption {
      description = ''
        Environment variables added to {option}`systemd.services."mindwtr-cloud".environment`

        Note that `null` values are filtered out by default

        For a list of recognized environment variables, see https://docs.mindwtr.app/data-sync/cloud-deployment#environment-variables
      '';
      apply = lib.converge (lib.filterAttrsRecursive (_: val: val != null && val != {} && val != []));
      type = types.submodule {
        freeformType = types.attrsOf (nullOr (types.oneOf [str types.path types.package]));

        options = {
          MINDWTR_CLOUD_AUTH_TOKENS_FILE = mkOption {
            type = types.path;
            default = null;
            description = ''
              Path to a file containing a comma-separated allowlist of bearer tokens.
              Each token must be 20-512 characters of letters, numbers, or `. _ ~ + / = -`; the server refuses to start otherwise.

              This is automatically added to {option}`systemd.services."mindwtr-cloud".serviceConfig.ReadOnlyPaths`
            '';
          };
          MINDWTR_CLOUD_CORS_ORIGIN = mkOption {
            type = nullOr str;
            default = null;
            example = "cloud.mindwtr.example.com";
            description = "";
          };
          MINDWTR_CLOUD_DATA_DIR = mkOption {
            type = nullOr types.str;
            description = ''
              Directory for JSON namespaces, attachments, and locks.

              This is automatically added to {option}`systemd.services."mindwtr-cloud".serviceConfig.ReadWritePaths`
            '';
          };
          MINDWTR_CLOUD_TRUST_PROXY_HEADERS = mkOption {
            type = nullOr types.str;
            default = null;
            example = "true";
            description = ''
              Trust `X-Forwarded-For`/proxy IP headers for auth-failure rate limiting

              Leave {option}`services.mindwtr.cloud.environment.MINDWTR_CLOUD_TRUST_PROXY_HEADERS` set to `false` unless the server is only reachable through your reverse proxy.
              If you enable it, set MINDWTR_CLOUD_TRUSTED_PROXY_IPS to the proxy addresses that are allowed to supply forwarded client IPs.
            '';
          };
          MINDWTR_CLOUD_TRUSTED_PROXY_IPS = lib.mkOption {
            type = nullOr (types.listOf str);
            default = null;
            example = ["127.0.0.1"];
            description = ''
              Proxy IP allowlist used when proxy headers are trusted

              Entries are automatically concatenated with `,` to produce the expected comma-separated list
            '';
            apply = ipList: lib.concatStringsSep "," ipList;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # TODO: add warnings when secrets are part of the nix store
    assertions = [
      {
        assertion =
          cfg.package != null;
        message = ''
          Please set the mindwtr cloud package
        '';
      }
    ];
    systemd.services."mindwtr-cloud" = {
      description = "Mindwtr cloud sync server";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      startLimitIntervalSec = 86400;
      startLimitBurst = 5;
      environment = {} // cfg.environment;
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -- --port ${toString cfg.port}";
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        NoNewPrivileges = true;
        LimitNPROC = 64;
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "full";
        ReadWritePaths =
          []
          ++ lib.optional (cfg.environment.MINDWTR_CLOUD_DATA_DIR != null) cfg.environment.MINDWTR_CLOUD_DATA_DIR;
        ReadOnlyPaths =
          []
          ++ lib.optional (cfg.environment.MINDWTR_CLOUD_AUTH_TOKENS_FILE != null) cfg.environment.MINDWTR_CLOUD_AUTH_TOKENS_FILE;
      };
    };

    users = {
      users = mkIf (cfg.user == "mindwtr-cloud") {
        "mindwtr-cloud" = {
          inherit (cfg) group;
          isSystemUser = true;
        };
      };
      groups = mkIf (cfg.group == "mindwtr-cloud") {"mindwtr-cloud" = {};};
    };
  };
}
