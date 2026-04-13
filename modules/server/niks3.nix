{
  flake.modules.nixos.homelab =
    { config, inputs, ... }:
    let
      domain = "cache.walawren.com";
    in
    {
      imports = [ inputs.niks3.nixosModules.default ];

      sops.secrets."backblaze/kiriwalawrencache/key-id".owner = "niks3";
      sops.secrets."backblaze/kiriwalawrencache/application-key".owner = "niks3";
      sops.secrets."niks3/api-token".owner = "niks3";
      sops.secrets."niks3/signing-key".owner = "niks3";

      services.niks3 = {
        enable = true;
        httpAddr = "127.0.0.1:5751";

        # S3 configuration
        s3 = {
          endpoint = "binaries.walawren.com"; # or your S3-compatible endpoint
          bucket = "kiriwalawrencache";
          region = "eu-central-003";
          useSSL = true;
          accessKeyFile = config.sops.secrets."backblaze/kiriwalawrencache/key-id".path;
          secretKeyFile = config.sops.secrets."backblaze/kiriwalawrencache/application-key".path;
        };

        # API authentication token (minimum 36 characters)
        apiTokenFile = config.sops.secrets."niks3/api-token".path;

        # Signing keys for NAR signing
        signKeyFiles = [ config.sops.secrets."niks3/signing-key".path ];

        # Public cache URL (optional) - if exposed via https
        # Generates a landing page with usage instructions and public keys
        cacheUrl = "https://${domain}";
      };

      services.nginx.virtualHosts.${domain} = {
        forceSSL = true;
        useACMEHost = config.system.ddns.domain;
        locations."/" = {
          proxyPass = "http://${config.services.niks3.httpAddr}";
          extraConfig = ''
            proxy_connect_timeout 300s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
          '';
        };
      };

    };
}
