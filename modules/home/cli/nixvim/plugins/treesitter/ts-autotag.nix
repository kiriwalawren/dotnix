{lib, ...}: {
  meta.doc = lib.mdDoc ''
    Automatic HTML/XML tag completion and management using Tree-sitter.

    Provides intelligent tag handling:
    - Automatic closing tag insertion for HTML/XML
    - Tag renaming synchronization (rename opening tag updates closing tag)
    - Tree-sitter powered accuracy for complex nested structures
    - Support for various markup languages and frameworks
    - Smart tag completion in web development contexts

    Essential for web development workflows, ensuring consistent
    tag structure and reducing manual tag management overhead.

    Links: [nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag)
  '';

  programs.nixvim.plugins.ts-autotag = {
    enable = true;
  };
}
