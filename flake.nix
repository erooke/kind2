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
    ocaml = pkgs.ocaml-ng.ocamlPackages_4_14;
    python = pkgs.python3.withPackages (ps: [ ps.pytest ]);
  in {
    formatter.${system} = pkgs.alejandra;

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        python
        # Dependencies
        ocaml.ocaml
        ocaml.dune_3
        ocaml.findlib
        ocaml.dune-build-info
        ocaml.menhir
        ocaml.menhirLib
        ocaml.num
        ocaml.odoc
        ocaml.ounit
        ocaml.yojson
        ocaml.zmq
        ocaml.ocaml-lsp
        ocaml.ocamlformat
        pkgs.czmq
        pkgs.z3
        # Dev Tools
        pkgs.graphviz
        pkgs.httplz
        pkgs.just
        pkgs.shellcheck
        pkgs.shfmt
      ];

      shellHook = ''
        PATH="$(pwd)/_build/install/default/bin:$PATH"
      '';
    };
  };
}
