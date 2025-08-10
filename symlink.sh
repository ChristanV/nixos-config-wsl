#!/usr/bin/env sh

echo "Symlinking configuration.nix"
ln -sf ~/nixos-config-wsl/configuration.nix /etc/nixos/configuration.nix
