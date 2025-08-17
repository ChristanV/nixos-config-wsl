# Run with 'nix-shell example.nix'
# Can use this as template for default.nix and just run new environments with 'nix-shell'

{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.nodejs_20 # Default to stable channel
  ];

  shellHook = ''
    echo 'Deno version from unstable channel'
    deno --version

    echo ' '

    echo 'Node version from default stable channel'
    node --version
  '';
}
