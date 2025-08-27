{
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = "\\";
      autoformat = true;
      markdown_recommended_style = 0; # Fix markdown indentation styles

      # LazyVim root dir detection
      # Each entry can be:
      # * the name of a detector function like `lsp` or `cwd`
      # * a pattern or array of patterns like `.git` or `lua`.
      # * a function with signature `function(buf) -> string|string[]`
      root_spec = ["lsp" [".git" "lua"] "cwd"];
    };

    opts = {
      autoread = true; # Enable auto reload of buffers (caveats resolved as auto commands)
      autowrite = true; # Enable auto write
      clipboard = "unnamedplus"; # Sync with system clipboard
      completeopt = "menu,menuone,noselect";
      conceallevel = 0;
      confirm = true; # Confirm to save changes before exiting modified buffer
      cursorline = true; # Enable highlighting of the current line
      expandtab = true; # Use spaces instead of tabs
      formatoptions = "jcroqlnt"; # tcqj
      foldenable = false;
      grepformat = "%f:%l:%c:%m";
      grepprg = "rg --vimgrep";
      hlsearch = false; # Don't keep searches highlighted after hitting enter
      ignorecase = true; # Ignore case
      inccommand = "nosplit"; # preview incremental substitute
      incsearch = true; # Incremental search
      laststatus = 3; # global statusline
      list = true; # Show some invisible characters (tabs...
      listchars = {
        space = "·";
        nbsp = "·";
        tab = ">-";
        extends = ">";
        precedes = "<";
        trail = "~";
        eol = "¬";
      };
      mouse = "a"; # Enable mouse mode
      number = true; # Print line number
      pumblend = 10; # Popup blend
      pumheight = 10; # Maximum number of entries in a popup
      relativenumber = false; # Relative line numbers
      scrolloff = 6; # Lines of context
      sessionoptions = ["buffers" "curdir" "tabpages" "winsize" "help" "globals" "skiprtp" "folds"];
      shiftround = true; # Round indent
      shiftwidth = 2; # Size of an indent
      # opt.shortmess:append({ W = true, I = true, c = true, C = true })
      showmode = false; # Dont show mode since we have a statusline
      sidescrolloff = 8; # Columns of context
      signcolumn = "yes"; # Always show the signcolumn, otherwise it would shift the text each time
      smartcase = true; # Don't ignore case with capitals
      smartindent = true; # Insert indents automatically
      # smoothscroll = true;
      softtabstop = 2;
      spelllang = ["en"];
      splitbelow = true; # Put new windows below current
      splitkeep = "screen";
      splitright = true; # Put new windows right of current
      tabstop = 2; # Number of spaces tabs count for
      termguicolors = true; # True color support
      timeoutlen = 300;
      undofile = true;
      undolevels = 10000;
      updatetime = 200; # Save swap file and trigger CursorHold
      virtualedit = "block"; # Allow cursor to move where there is no text in visual block mode
      wildmode = "longest:full,full"; # Command-line completion mode
      winminwidth = 5; # Minimum window width
      wrap = false; # Disable line wrap
      fillchars = {
        foldopen = "";
        foldclose = "";
        fold = " ";
        foldsep = " ";
        diff = "╱";
        eob = " ";
      };
    };
  };
}
