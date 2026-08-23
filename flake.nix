{
  description = "Containerized Dedicated Servers for Warframe's Conclave";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs:
    inputs.utils.lib.eachDefaultSystem (
      system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            gofmt.enable = true;
          };
        };
      in {
        formatter = treefmt.config.build.wrapper;

        devShells.default = pkgs.mkShell {
          name = "arcata";

          buildInputs = with pkgs; [
            go
            gopls
          ];
        };
      }
    );
}
