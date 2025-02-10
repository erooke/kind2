{
  fetchzip,
  stdenv,
  jre,
}: let
  version = "4.5.2";
  pname = "jkind";
  entry_points = [
    "jkind"
    "jlustre2kind"
    "jlustre2excel"
    "jrealizability"
    "benchmark"
  ];
in
  stdenv.mkDerivation {
    inherit pname version;
    src = fetchzip {
      url = "https://github.com/loonwerks/jkind/releases/download/v${version}/jkind-${version}.zip";
      hash = "sha256-1pF/F+L2Ovt79veqYLQcxhbgp8vElBY67raVShb+3tI=";
    };

    installPhase = let
      mk_script = jar: entry: ''
        cat > $out/bin/${entry} <<EOF
        #!/bin/sh
        exec ${jre}/bin/java -jar ${jar} -${entry} "\$@"
        EOF
        chmod +x $out/bin/${entry}
      '';
    in
      builtins.concatStringsSep "\n" ([
          ''
            mkdir -p $out/{bin,share/jkind}
            find $src -type f -name "*.jar" -exec cp -t $out/share/jkind/ {} +
          ''
        ]
        ++ map (mk_script "$out/share/jkind/jkind.jar") entry_points);
  }
