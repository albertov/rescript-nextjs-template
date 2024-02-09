{ stdenv
, python3
, nodejs
, inputs
, ocamlPackages
, ninja
, jq
}:
stdenv.mkDerivation {
  name = "rescript";
  version = inputs.rescript-compiler.rev;
  src = inputs.rescript-compiler;
  nativeBuildInputs = with ocamlPackages; [
    ocaml
    dune_3
    nodejs
    python3
    cppo
    jq
  ];
  buildInputs = with ocamlPackages; [
    ounit2
    findlib
  ];
  postPatch = ''
    patchShebangs --build ./scripts/buildNinjaBinary.js
    patchShebangs --build ./scripts/copyExes.js
  '';
  installPhase = ''
    mkdir $out
    jq -c -r '.files | .[]' package.json | while read file; do
      mkdir -p $out/$(dirname $file)
      cp -av $file $out/$file || true
    done
    patchShebangs --build $out/rescript
    patchShebangs --build $out/bsc
    patchShebangs --build $out/lib/bstracing
  '';
}
