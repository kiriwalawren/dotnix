{
  flake.modules.nixos.base =
    let
      locale = "en_US.UTF-8";
    in
    {
      # Set your time zone.
      time.timeZone = "America/New_York";

      # Select internationalisation properties.
      i18n.defaultLocale = locale;

      i18n.extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
      };
    };
}
