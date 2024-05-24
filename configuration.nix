# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:
  let
    unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
  in {
    environment.systemPackages = with pkgs; [
      # Core Packages
      neovim
      gnumake
      busybox

      # Core Development Packages
      awscli2
      python310Packages.ansible-core
      docker
      kubectl
      kubectx
      git
      azure-cli
      unstable.terraform
      python3
      postgresql

      # LSP's
      yaml-language-server
      ansible-language-server
      ansible-lint
      lua-language-server
      nodePackages.typescript-language-server
      nodePackages.bash-language-server
      java-language-server
      dockerfile-language-server-nodejs
    ];
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  wsl.enable = true;
  wsl.defaultUser = "christan";
  wsl.wslConf.network.hostname = "chrisdevops";
  wsl.wslConf.network.generateResolvConf = false;
  wsl.wslConf.boot.command = ""; #Default startup commands
  wsl.wslConf.user.default = "christan";
  
  networking.nameservers = ["8.8.8.8" "1.1.1.1"];

  environment.etc = {
    "resolv.conf".text = "nameserver 8.8.8.8\n nameerver 1.1.1.1";
  };

  environment.etc."bashrc".text = ''
    alias kc='kubectl'
    alias kctx='kubectx'
    alias kns='kubens'
    alias tf='terraform'
    alias vi='nvim'
    alias nix='sudo nixos-rebuild switch'
  '';

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "terraform"
  ];

  #Docker-desktop workaround to work with WSL
  #Enable WSL integration on docker desktop
  #https://github.com/nix-community/NixOS-WSL/issues/235
  wsl.docker-desktop.enable = false;
  wsl.extraBin = with pkgs; [
      # Binaries for Docker Desktop wsl-distro-proxy
      { src = "${coreutils}/bin/mkdir"; }
      { src = "${coreutils}/bin/cat"; }
      { src = "${coreutils}/bin/whoami"; }
      { src = "${coreutils}/bin/ls"; }
      { src = "${busybox}/bin/addgroup"; }
      { src = "${su}/bin/groupadd"; }
      { src = "${su}/bin/usermod"; }
  ];
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  systemd.services.docker-desktop-proxy.script = lib.mkForce ''${config.wsl.wslConf.automount.root}/wsl/docker-desktop/docker-desktop-user-distro proxy --docker-desktop-root ${config.wsl.wslConf.automount.root}/wsl/docker-desktop "C:\Program Files\Docker\Docker\resources"'';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
