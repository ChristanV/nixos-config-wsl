{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      nixpkgs,
      nixos-wsl,
      nixpkgs-unstable,
      vscode-server,
      claude-code,
      ...
    }@inputs:
    let
      var = import ./var.nix;
    in
    {
      nixosConfigurations."${var.hostname}" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          { nix.registry.nixpkgs.flake = nixpkgs; }
          ./configuration.nix
          nixos-wsl.nixosModules.wsl
          vscode-server.nixosModules.default

          (
            { config, pkgs, ... }:
            let
              # unstable prefix in systemPackages to use unstable package instead.
              unstable = import nixpkgs-unstable {
                inherit (config.nixpkgs) system;
                inherit (config.nixpkgs) config;
              };
            in
            {
              _module.args = { inherit var; };

              # Use always latest version with prefix in systemPackages
              nixpkgs.overlays = [ claude-code.overlays.default ];

              services.vscode-server.enable = true;

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
                virtualenv
                kubectl
                kubectx
                kubelogin
                git
                postgresql
                eksctl
                lazygit
                fd
                ripgrep
                zoxide
                chromium
                flyctl
                sops
                gnupg
                k9s
                ssm-session-manager-plugin
                awscli2
                docker_28
                docker-compose
                (azure-cli.withExtensions [
                  pkgs.azure-cli-extensions.bastion
                  pkgs.azure-cli-extensions.ssh
                ])

                # LSP's for neovim
                terraform-ls
                tflint
                yaml-language-server
                ansible-language-server
                ansible-lint
                lua-language-server
                nodePackages.typescript-language-server
                nodePackages.bash-language-server
                jdt-language-server
                postgres-lsp

                # Linters and checkers
                statix
                deadnix

                dockerfile-language-server-nodejs
                pyright
                gopls
                nodePackages.typescript-language-server
                helm-ls
                nixd

                # Development
                terragrunt
                python311
                python311Packages.pip
                poetry
                go
                nodejs_24
                typescript
                lua
                yarn
                k3s
                minikube
                jdk23
                nixfmt-rfc-style
                gitleaks
                pre-commit
                unstable.terraform
                trunk-io
                tfsec
                terraform-docs
                tfupdate
                terrascan
                unstable.claude-code
                gemini-cli
                gh

                # Security
                clamav
                unstable._1password-cli

                # Other
                fastfetch
                starship
                zsh
                zsh-fzf-tab
                glow
                steampipe
                btop
                fzf
                plantuml
                graphviz
                xclip
                cacert
              ];
            }
          )
        ];
      };
    };
}
