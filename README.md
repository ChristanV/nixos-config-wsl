# NixOs Configuration for WSL - Quickstart

My custom NixOs configuration for WSL

## Setup and configure

Make sure the following is installed for this quickstart.

* WSL version 2
* docker-Desktop
* vscode #optional

### 1.Install NixOs

Download the WSL distribution for NixOS follow reference link below.

Reference: https://nixos.wiki/wiki/WSL
Packages: https://search.nixos.org/packages

In Powershell run
* `wsl --update`
* `wsl --import NixOS .\NixOS\ nixos-wsl.tar.gz --version 2`
* `wsl -d NixOS`

### 2. Setup NixOs
* `sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable`
* `sudo nix-channel --update && sudo nixos-rebuild switch`
* `nix-env -iA nixos.neovim` #Optional step (use own editor preference)
* `nix-env -iA nixos.git`
* `nix-env -iA nixos.gnumake`

Clone the repo and edit variables if needed
Copy configuration.nix in /etc/nixos/configuration.nix

Alternatively run using the included makefile.

1. `sudo make set-config`

2. `sudo make switch`

Finally run

`sudo nixos-rebuild switch`

On first install restart WSL 

`wsl --shudown`

### 3. Set NixOs as default WSL Distro
In Powershell run  
* `wsl -s NixOS`
* `wsl -d NixOS`


### Notes

Known unstable items I am still trying to resolve.

* docker-desktop integration
* vscode remote integration

See samples folder for configuration files for nix shell for dev environments

I have no idea how nix flakes work.
