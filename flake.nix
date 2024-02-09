{
  description = "Rescript bindings for ReactBootstrap";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable-small;
    flake-utils.url = github:numtide/flake-utils;
    rescript-compiler = {
      url = github:rescript-lang/rescript-compiler?ref=v11.0.1;
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    {
      overlays.default = import ./nix/overlay.nix {
        inherit inputs;
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.outputs.overlays.default
          ];
        };
        yarnBuild = pkgs.mkYarnPackage {
          name = "rescript-react-bootstrap";
          version = "0.0.1";
          src = ./.;
          packageJSON = ./package.json;
          yarnLock = ./yarn.lock;

          nativeBuildInputs = with pkgs; [ nodejs_21 python39 ];
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        legacyPackages = pkgs;
        devShell = pkgs.mkShell {
          name = "rescript-react-bootstrap";
          buildInputs = with pkgs; with pkgs.nodePackages; [
            nodejs_21
            yarn
            python39
            yarnBuild
          ];
          shellHook = ''export PATH="./node_modules/.bin:$PATH"'';
        };
      });
}
