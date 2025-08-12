# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{ config, pkgs, var, ... }:

{
  system.stateVersion = "25.05";

  # DNS fix for WSL2
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    allowUnsupportedSystem = false;
  };

  # Allow linked libraries
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs; # Fix for vscode 24.05
    libraries = config.hardware.graphics.extraPackages;
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings.features.cdi = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = {
        features.cdi = true;
        cdi-spec-dirs = [ "/home/${var.username}/.cdi" ];
      };
    };
  };

  services = {
    clamav = {
      daemon.enable = true;
      updater.enable = true;
    };
  };

  security.apparmor.enable = true;
  security.audit.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users."${var.username}" = {
    extraGroups = [ "docker" ];
    shell = pkgs.zsh;
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "z"
        "history"
        "sudo"
        "docker"
        "docker-compose"
        "aws"
        "azure"
        "argocd"
        "kubectl"
        "kubectx"
        "pip"
        "ssh"
        "terraform"
      ];
    };

    # Persist ENV vars accross terminal instances
    shellInit = ''
      AWS_SECRETS_FILE="$HOME/.config/secrets/awsenv"
      awsctx() {
          local profile
          
          # Create secrets directory if it doesn't exist
          mkdir -p "$(dirname "$AWS_SECRETS_FILE")"
          
          # Get profile selection
          profile=$(sed -n "s/\[profile \(.*\)\]/\1/gp" ~/.aws/config | fzf)
          
          if [ -n "$profile" ]; then
              # Export for current session
              export AWS_PROFILE="$profile"
              
              # Update secrets file for persistence
              if [ -f "$AWS_SECRETS_FILE" ]; then
                  # Remove existing AWS_PROFILE line
                  sed -i '/^export AWS_PROFILE=/d' "$AWS_SECRETS_FILE"
              else
                  touch "$AWS_SECRETS_FILE"
                  chmod 600 "$AWS_SECRETS_FILE"
              fi
              
              # Add new AWS_PROFILE line
              echo "export AWS_PROFILE=\"$profile\"" >> "$AWS_SECRETS_FILE"
          else
              echo "No profile selected"
          fi
      }

      ONEPASS_SECRETS_FILE="$HOME/.config/secrets/onepassenv"
      oplogin() {
          local session_token
          local account_id
          
          # Create secrets directory if it doesn't exist
          mkdir -p "$(dirname "$ONEPASS_SECRETS_FILE")"
          
          echo "Signing in to 1Password..."
          session_token=$(op signin --raw)
          if [ -n "$session_token" ]; then
              # Get the account ID dynamically
              account_id=$(op account list --format=json | jq -r '.[0].user_uuid' 2>/dev/null)
              
              if [ -z "$account_id" ]; then
                  echo "Warning: Could not determine account ID, using generic session variable"
                  account_id="default"
              fi
              
              local session_var="OP_SESSION_$account_id"
              
              # Export for current session
              export "$session_var=$session_token"
              
              # Update secrets file for persistence
              if [ -f "$ONEPASS_SECRETS_FILE" ]; then
                  # Remove any existing OP_SESSION_* variables
                  sed -i '/^export OP_SESSION_.*=/d' "$ONEPASS_SECRETS_FILE"
              else
                  touch "$ONEPASS_SECRETS_FILE"
                  chmod 600 "$ONEPASS_SECRETS_FILE"
              fi
              
              echo "export $session_var=\"$session_token\"" >> "$ONEPASS_SECRETS_FILE"
              
              # Load env vars from ONEPASS
              if [ -f "$HOME/.config/secrets/env" ]; then
                  source "$HOME/.config/secrets/env"
              fi
              
              echo "✅ Signed in to 1Password (session: $session_var)"
          else
              echo "❌ Failed to sign in to 1Password"
              return 1
          fi
      }
    '';

    # Source secrets file on every shell initialization
    interactiveShellInit = ''
      if [ -f "$HOME/.config/secrets/awsenv" ]; then
          source "$HOME/.config/secrets/awsenv"
      fi

      if [ -f "$HOME/.config/secrets/onepassenv" ]; then
          source "$HOME/.config/secrets/onepassenv"
      fi

      # Source Other env vars - manually add these (only if 1Password CLI is logged in)
      if op whoami >/dev/null 2>&1 && [ -f "$HOME/.config/secrets/env" ]; then
        source "$HOME/.config/secrets/env"
      fi
    '';
  };

  environment.etc."zshrc".text = ''
    eval "$(starship init zsh)"
    alias kc='kubectl'
    alias kctx='kubectx'
    alias kns='kubens'
    alias tf='terraform'
    alias tg='terragrunt'
    alias vi='nvim .'
    alias nixr='sudo nixos-rebuild switch'
    alias nixb='nixos-rebuild build'
    alias nixs='nix-shell'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
    alias lg=lazygit
    alias kcgp='kc get pods -l app.kubernetes.io/instance='
    alias kcgd='kc get deploy -l app.kubernetes.io/instance='
    alias kctp='kc top pods --containers -l app.kubernetes.io/instance='

    # Disabling paging by default
    export PAGER=cat
    export LESS=

    export EDITOR="nvim"
    export KUBE_CONFIG_PATH=~/.kube/config
    export STARSHIP_CONFIG=~/.config/starship-config/starship.toml

    keep_current_path() {
      printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"
    }
    precmd_functions+=(keep_current_path)

    cat << EOF > ~/.zshrc
    ZSH_HIGHLIGHT_STYLES[comment]='fg=8'                # gray
    ZSH_HIGHLIGHT_STYLES[command]='fg=#769ff0'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=#769ff0'
    ZSH_HIGHLIGHT_STYLES[function]='fg=#769ff0'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=#769ff0'
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=red'
    ZSH_HIGHLIGHT_STYLES[path]='fg=white'
    EOF
  '';

  systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash" ];

  wsl = {
    enable = true;
    defaultUser = var.username;
    wslConf.network.hostname = var.hostname;
    wslConf.network.generateResolvConf = false;
    wslConf.boot.command = ""; # Default startup commands
    wslConf.user.default = var.username;
    useWindowsDriver = true;

    extraBin = with pkgs; [
      { src = "${coreutils}/bin/mkdir"; }
      { src = "${coreutils}/bin/cat"; }
      { src = "${coreutils}/bin/whoami"; }
      { src = "${coreutils}/bin/ls"; }
      { src = "${busybox}/bin/addgroup"; }
      { src = "${coreutils}/bin/uname"; }
      { src = "${coreutils}/bin/dirname"; }
      { src = "${coreutils}/bin/readlink"; }
      {
        src = "${coreutils}/bin/sed";
      }

      # Allows .sh files to be run
      { src = "/run/current-system/sw/bin/sed"; }
      { src = "${su}/bin/groupadd"; }
      { src = "${su}/bin/usermod"; }
    ];
  };
}
