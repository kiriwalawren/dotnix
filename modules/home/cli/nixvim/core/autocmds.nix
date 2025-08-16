{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Essential autocommands for maintaining clean code formatting.

    Provides automatic code maintenance:
    - Trailing whitespace removal on file save
    - Consistent file formatting across all file types
    - Automatic cleanup without manual intervention
    - Improved code quality and consistency

    Ensures all saved files maintain clean formatting standards
    by automatically removing trailing whitespace.
  '';

  programs.nixvim.autoCmd = [
    # Automatically trim all whitespace an save
    {
      event = ["BufWritePre"];
      pattern = ["*"];
      command = ":%s/\\s\\+$//e";
    }
  ];
}
