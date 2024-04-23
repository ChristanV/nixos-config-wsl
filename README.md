# nix-config

Install

wsl --import NixOS .\NixOS\ nixos-wsl.tar.gz --version 2
wsl -d NixOS
sudo nix-channel --update && sudo nixos-rebuild switch
nix-env -iA nixos.neovim
sudo nvim /etc/nixos/configuration.nix
exit
wsl --shutdown
wsl -s NixOS
wsl -d NixOS




##

To run unstable packages 
nix-shell -I nixpkgs=channel:nixpkgs-unstable -p somepackage

Normal shell without .nix
nix-shell -p somePackage
