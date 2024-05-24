set-config:
	@cp -f configuration.nix /etc/nixos/configuration.nix

switch:
	@nixos-rebuild switch

build:
	@nixos-rebuild build

boot:
	@nixos-rebuild boot

test:
	@nixos-rebuild test