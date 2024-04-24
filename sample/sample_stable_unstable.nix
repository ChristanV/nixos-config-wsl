{ pkgs ? import <nixpkgs> {}, unstable ? import<nixos-unstable> {} }:


pkgs.mkShell {
  buildInputs = [
    unstable.deno
    pkgs.nodejs_21
  ];
}


