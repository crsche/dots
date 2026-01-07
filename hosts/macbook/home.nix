{ pkgs, lib, ... }:
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    procs # ps
    dust # du
    xh # curl

    (lib.hiPrio gitoxide) # better git
    gitMinimal # standard git

    ghostty-bin
  ];

  programs = {
    brave.enable = true;

    fish.enable = true;
    direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
    gpg.enable = true;
    keychain.enable = true;
    password-store.enable = true;

    # --- cli tools ---
    # ls
    eza.enable = true;
    # cat
    bat.enable = true;
    # fd
    fd.enable = true;
    # grep
    ripgrep.enable = true;
    ripgrep-all.enable = true;
    # replace jq with jaq
    jq = {
      enable = true;
      package = pkgs.jaq;
    };
    # top
    bottom.enable = true;
    # cd
    zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };
    # wget
    aria2.enable = true;

    git = {
      enable = true;
      package = pkgs.gitMinimal;
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };

    fzf = {
      enable = true;
    };

    nh.enable = true;
    grep.enable = true;
  };

  services = {
    ssh-agent.enable = true;
    gpg-agent.enable = true;

    tldr-update = {
      enable = true;
      package = pkgs.tealdeer;
    };
  };
}
