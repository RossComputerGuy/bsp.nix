{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/*";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;

      flake.overlays.default = import ./pkgs;

      perSystem =
        {
          pkgs,
          system,
          lib,
          ...
        }:
        let
          eachPlatform = lib.genAttrs [
            "asrock-rack/altrad8ud-1l2t"
          ];
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.self.overlays.default
            ];
          };

          packages = eachPlatform (name: pkgs.callPackage (./. + "/platforms/${name}") { });
        };
    };
}
