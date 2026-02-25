{
  flake.modules.nixos.auth =
    { config, lib, ... }:
    let
      domain = "auth.${config.system.ddns.domain}";
    in
    {
      options.system.auth = {
        issuer = lib.mkOption {
          type = lib.types.str;
          default = "https://${domain}";
          readOnly = true;
        };
      };

      config = {
        system.ddns.subdomains = [ "auth" ];

        sops.secrets = {
          "pocket-id/encryption-key" = {
            owner = "pocket-id";
            group = "pocket-id";
          };

          "pocket-id/smtp-secret" = {
            owner = "pocket-id";
            group = "pocket-id";
          };
        };

        services.pocket-id = {
          enable = true;
          credentials = {
            ENCRYPTION_KEY = config.sops.secrets."pocket-id/encryption-key".path;
          };
          settings = {
            APP_URL = config.system.auth.issuer;
            TRUST_PROXY = true;
            PORT = 1411;
            UI_CONFIG_DISABLED = true;
            ACCENT_COLOR = "#009c84";
            ALLOW_USER_SIGNUPS = "withToken";
            DISABLE_ANIMATIONS = true;
            SMTP_HOST = "smtp.protonmail.ch";
            SMTP_PORT = 587;
            SMTP_USER = "kiri@walawren.com";
            SMTP_PASSWORD_FILE = config.sops.secrets."pocket-id/smtp-secret".path;
            SMTP_TLS = "starttls";
            SMTP_FROM = "auth@walawren.com";
            EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
            EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED = true;
            EMAIL_VERIFICATION_ENABLED = true;
          };
        };

        services.nginx.virtualHosts.${domain} = {
          useACMEHost = config.system.ddns.domain;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:1411";
            proxyWebsockets = true;
          };
        };
      };
    };
}
