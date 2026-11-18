{
  flake.modules.nixvim.base.autoCmd = [
    {
      desc = "Automatically trim all whitespace an save";
      event = [ "BufWritePre" ];
      pattern = [ "*" ];
      command = ":%s/\\s\\+$//e";
    }
    {
      desc = ''
        Triger `autoread` when files changes on disk
        https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
        https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
      '';
      event = [
        "FocusGained"
        "BufEnter"
        "CursorHold"
        "CursorHoldI"
      ];
      pattern = [ "*" ];
      command = "if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif";
    }
    {
      desc = ''
        Notification after file change
        https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
      '';
      event = [ "FileChangedShellPost" ];
      pattern = [ "*" ];
      command = "echohl WarningMsg | echo \"File changed on disk. Buffer reloaded.\" | echohl None";
    }
  ];
}
