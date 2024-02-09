{ inputs }:
final: prev: {
  rescript = final.callPackage ./pkgs/rescript.nix {
    inherit inputs;
  };
}
