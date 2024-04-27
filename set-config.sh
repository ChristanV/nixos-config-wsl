#! /run/current-system/sw/bin/bash
#
# Run this from nixos
echo 'make sure this is run in sudo'

echo 'Copying the configuration file from repo to /etc/nixos/configuration'
cp -f configuration.nix /etc/nixos/configuration.nix
