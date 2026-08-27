{ lib, ... }:
{
  options.theme.colorSchemeName = lib.mkOption {
    type = lib.types.str;
    default = "Catppuccin";
    description = "Noctalia's currently active color scheme name.";
  };
}
