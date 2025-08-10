switch:
	@echo 'Switching to new NixOs configuration'
	@nixos-rebuild switch

build:
	@echo 'Building new NixOs configuration'
	@nixos-rebuild build

boot:
	@echo 'Boot to new NixOs configuration'
	@nixos-rebuild boot

test:
	@echo 'Test new NixOs configuration'
	@nixos-rebuild test

channel-update:
	@nix-channel --update

cleanup:
	@nix-collect-garbage -d --delete-older-than 10d

upgrade:
	@echo 'Upgrade to new NixOs configuration'
	@nixos-rebuild switch --upgrade

format:
	@nixfmt configuration.nix
