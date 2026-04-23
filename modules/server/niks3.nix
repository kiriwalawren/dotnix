{
  flake.modules.nixos.homelab =
    { config, inputs, ... }:
    let
      domain = "niks3.walawren.com";
    in
    {
      imports = [ inputs.niks3.nixosModules.default ];

      sops.secrets."backblaze/kiriwalawrencache/key-id".owner = config.services.niks3.user;
      sops.secrets."backblaze/kiriwalawrencache/application-key".owner = config.services.niks3.user;
      sops.secrets."niks3/api-token".owner = config.services.niks3.user;
      sops.secrets."niks3/signing-key".owner = config.services.niks3.user;

      services.niks3 = {
        enable = true;
        httpAddr = "127.0.0.1:5751";

        s3 = {
          endpoint = "s3.us-east-005.backblazeb2.com"; # or your S3-compatible endpoint
          bucket = "kiriwalawrencache";
          region = "us-east-005";
          useSSL = true;
          accessKeyFile = config.sops.secrets."backblaze/kiriwalawrencache/key-id".path;
          secretKeyFile = config.sops.secrets."backblaze/kiriwalawrencache/application-key".path;
        };

        apiTokenFile = config.sops.secrets."niks3/api-token".path;

        signKeyFiles = [ config.sops.secrets."niks3/signing-key".path ];

        cacheUrl = "https://cache.walawren.com";

        oidc.providers.github = {
          issuer = "https://token.actions.githubusercontent.com";
          audience = "https://niks3.walawren.com";
          boundClaims = {
            repository_owner = [ "kiriwalawren" ];
          };
        };
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
