# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{ config, lib, pkgs, ... }:
  let
    unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
    username = "christan"; # Use own username
    hostname = "chrisdevops"; # Use own hostname
  in {

    # Using stable channel packages by default prefix with 'unstable.' 
    # for latest versions
    environment.systemPackages = with pkgs; [
      # Core Packages
      neovim
      gnumake
      busybox
      wget
      stern
      jq
      yq
      kubernetes-helm
      openssl
      go-task

      # Core Development Packages
      awscli2
      python310Packages.ansible-core
      docker
      kubectl
      kubectx
      kubelogin
      git
      azure-cli
      unstable.terraform
      python3
      postgresql
      eksctl

      # LSP's for neovim
      terraform-ls
      tflint
      yaml-language-server
      ansible-language-server
      ansible-lint
      lua-language-server
      nodePackages.typescript-language-server
      nodePackages.bash-language-server
      java-language-server
      dockerfile-language-server-nodejs
      pyright

      # Other
      fd
      ripgrep
      google-chrome
    ];
  imports = [
    # Include NixOS-WSL modules
    <nixos-wsl/modules>

    # vscode integration https://github.com/nix-community/nixos-vscode-server
    (fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
  ];
  
  # Licenced Packages
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "terraform"
    "google-chrome"
  ];

  services.vscode-server.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Base WSL setup
  wsl = {
    enable = true;
    defaultUser = username;
    wslConf.network.hostname = hostname;
    wslConf.network.generateResolvConf = false;
    wslConf.boot.command = ""; #Default startup commands
    wslConf.user.default = username;

    # Docker-desktop workaround to work with WSL
    # Enable WSL integration on docker desktop
    # https://github.com/nix-community/NixOS-WSL/issues/235
    docker-desktop.enable = false;
    extraBin = with pkgs; [
      # Binaries for Docker Desktop wsl-distro-proxy
      { src = "${coreutils}/bin/mkdir"; }
      { src = "${coreutils}/bin/cat"; }
      { src = "${coreutils}/bin/whoami"; }
      { src = "${coreutils}/bin/ls"; }
      { src = "${busybox}/bin/addgroup"; }
      { src = "${coreutils}/bin/uname"; }
      { src = "${coreutils}/bin/dirname"; }
      { src = "${coreutils}/bin/readlink"; }
      { src = "${coreutils}/bin/sed"; }
      { src = "/run/current-system/sw/bin/sed"; }
      { src = "${su}/bin/groupadd"; }
      { src = "${su}/bin/usermod"; }
    ];
  };
  
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  systemd.services.docker-desktop-proxy.script = lib.mkForce ''
    ${config.wsl.wslConf.automount.root}/wsl/docker-desktop/docker-desktop-user-distro proxy --docker-desktop-root ${config.wsl.wslConf.automount.root}/wsl/docker-desktop "C:\Program Files\Docker\Docker\resources"
  '';
  
  networking.nameservers = ["8.8.8.8" "1.1.1.1"];

  environment.etc = {
    "resolv.conf".text = "nameserver 8.8.8.8\n nameserver 1.1.1.1";
  };

  # Set bash aliases and default editor
  environment.etc."bashrc".text = ''
    alias kc='kubectl'
    alias kctx='kubectx'
    alias kns='kubens'
    alias tf='terraform'
    alias vi='nvim .'
    alias nixr='sudo nixos-rebuild switch'
    alias nixb='nixos-rebuild build'
    alias nixs='nix-shell'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
    alias kcgp='kc get pods -l app.kubernetes.io/instance='
    alias kcgd='kc get deploy -l app.kubernetes.io/instance='
    alias kctp='kc top pods --containers -l app.kubernetes.io/instance='
    export EDITOR="nvim"
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
