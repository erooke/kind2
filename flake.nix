{
  description = "P models for UxAS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.ocamlPackages.ocaml
        pkgs.ocamlPackages.dune_3
        pkgs.ocamlPackages.findlib
        pkgs.ocamlPackages.dune-build-info
        pkgs.ocamlPackages.menhir
        pkgs.ocamlPackages.menhirLib
        pkgs.ocamlPackages.num
        pkgs.ocamlPackages.odoc
        pkgs.ocamlPackages.ounit
        pkgs.ocamlPackages.yojson
        pkgs.ocamlPackages.zmq
        pkgs.ocamlPackages.ocaml-lsp
        pkgs.ocamlPackages.ocamlformat
        pkgs.ocamlPackages.utop
        pkgs.czmq
        pkgs.z3
      ];

      shellHook = ''
        PATH="$(pwd)/_build/install/default/bin:$PATH"
      '';
    };
  };
}
