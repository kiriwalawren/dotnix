{
  config,
  lib,
  ...
}:
with lib;
{
  config = mkIf config.server.nixflix.enable {
    # sops.secrets."qbittorrent/password" = { };

    nixflix.qbittorrent = {
      enable = true;
      password = "test123";
      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
          WebUI = {
            Username = "admin";
            Password_PBKDF2 = "@ByteArray(mLsFJ3Dsd3+uZt52Vu9FxA==:ON7uV17wWL0mlay5m5i7PYeBusWa7dgiH+eJG8wC/t+zihfqauUTS0q6DKTwsB5YtbOcmztixnuezjjApywXlw==)";
          };
          General.Locale = "en";
        };
      };
    };
  };
}
