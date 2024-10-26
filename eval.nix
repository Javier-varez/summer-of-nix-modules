let
  pkgs = import <nixpkgs> {
    config = { };
    overlays = [ ];
  };
in
pkgs.lib.evalModules {
  modules = [
    (
      { config, ... }:
      {
        config._module.args = {
          inherit pkgs;
        };
      }
    )
    ./default.nix
  ];
}
