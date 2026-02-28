{ lib, ... }:
{
  options.theme = {
    radius = lib.mkOption {
      type = lib.types.number;
      default = 10.0;
    };
  };
}
