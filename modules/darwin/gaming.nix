_: {
  environment = {
    etc."gitconfig".text = ''
      [filter "lfs"]
        clean = git-lfs clean -- %f
        smudge = git-lfs smudge -- %f
        process = git-lfs filter-process
        required = true
    '';
    variables = {
      RLIMIT_NOFILE = "65536";
    };
  };
}
