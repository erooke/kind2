{
  description = "P models for UxAS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self
    , nixpkgs
    ,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      formatter.${system} = pkgs.alejandra;

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          ocamlPackages.ocaml
          ocamlPackages.dune_3
          ocamlPackages.findlib
          ocamlPackages.dune-build-info
          ocamlPackages.menhir
          ocamlPackages.menhirLib
          ocamlPackages.num
          ocamlPackages.odoc
          ocamlPackages.ounit
          ocamlPackages.yojson
          ocamlPackages.zmq
          czmq
          z3
        ];
      };
    };
}
