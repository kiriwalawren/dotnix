{ lib, ... }:
{
  options.theme = {
    font = lib.mkOption {
      type = lib.types.str;
      default = "Maple Mono";
    };
    fontSizeSmall = lib.mkOption {
      type = lib.types.number;
      default = 12;
    };
    fontSize = lib.mkOption {
      type = lib.types.number;
      default = 14;
    };
  };
}
