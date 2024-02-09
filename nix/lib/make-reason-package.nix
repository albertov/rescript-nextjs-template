{ name
, src
, yarnLock ? "${src}/yarn.lock"
, packageJSON ? "${src}/package.json"
, yarnNix ? null
, nodeEnv ? "production"
, ocaml_exported ? null
, modulesPreBuild ? ""
, modulesPostBuild ? ""
, preInstallFixup ? ""
, doCheck ? true
, preBuild ? "export NODE_OPTIONS=--max_old_space_size=8192"
, postBuild ? ""
, preCheck ? ""
, installPhase ? ''
    if [[ -d build ]]; then
      mv build $out
    elif [[ -d dist ]]; then
      mv dist $out
    else
      echo "No build or dist found in output dir. Provide a custom installPhase"
      exit -1
    fi
  ''
, localDeps ? [ ]
, shellHook ? ""
, pkgConfig ? { }
, version ? "0.0.0"
, inputs
, plow
}:
{ stdenv
, lib
, yarn
, nodejs
, rsync
, openjdk
, utillinux
, mkYarnModules
, runCommandLocal
, yarn2nix
, rescript
, writeShellApplication
}:
let

  yarnNix' =
    if yarnNix == null
    then
      runCommandLocal "yarn.nix"
        {
          nativeBuildInputs = [ yarn2nix ];
          allowSubstitutes = true;
        }
        "yarn2nix --lockfile ${yarnLock} --no-patch --builtin-fetchgit > $out"
    else yarnNix
  ;

  copyNixNodeModules = writeShellApplication {
    name = "copy-nix-node-modules";
    text = ''
      if [ -d node_modules ]; then
        echo "Will not copy node_modules because node_modules already exists"
        echo "To proceed move it elsewhere or delete it and run this command again"
      else
        ${bringModules}
      fi
    '';
  };

  nixYarnInstall = writeShellApplication {
    name = "nix-yarn-install";
    runtimeInputs = [
      copyNixNodeModules
      yarn
    ];
    text = ''
      copy-nix-node-modules
      ${yarnPreinstall}
    '';
  };

  node_modules = mkYarnModules
    {
      yarnNix = yarnNix';
      inherit version yarnLock packageJSON pkgConfig;
      pname = "${name}-modules-${version}";
      name = "${name}-modules";


      # This yarn `preBuild` hook is executed before yarn install is called
      # by yarn2nix. It copies all localDeps into the build dir so
      # yarn can find them in the place it expects them
      preBuild = ''
        ${lib.concatMapStrings (path: "unpackFile ${path};") localDeps}
        ${modulesPreBuild}
      '';

      # We inject the compiled rescript into node_modules. We could have built
      # it in place here usingt pkgConfig but we don't because that would cause
      # it to be re-compiled every time package.json or yarn.lock is modified,
      # which we rather not since that means that whenever we bump up the
      # version in package.json we would suffer a rescript recompile
      postBuild = ''
        rm -rf $out/node_modules/rescript
        ln -s ${rescript} $out/node_modules/rescript
        ${modulesPostBuild}
      '';
    };

  bringModules = ''
    cp  --reflink=auto -R --no-preserve=mode \
      ${node_modules}/node_modules .
    (chmod -R a+rwx node_modules 2>/dev/null) || true
  '';

  yarnPreinstall = ''
    # yarn preinstall was not executed by yarn2nix so run it here and fixup
    if grep -q '"preinstall"' package.json; then
      yarn preinstall
    fi
    ${preInstallFixup}
  '';

in
stdenv.mkDerivation {
  inherit name src doCheck preBuild postBuild preCheck installPhase;

  buildInputs = [ node_modules ];

  nativeBuildInputs = [
    nodejs
    yarn
    openjdk
    rsync
    utillinux
  ];

  buildPhase = ''
    runHook preBuild

    # First bring in the node_modules from the "modules" derivation
    ${bringModules}
    export PATH=$(pwd)/node_modules/.bin:$PATH

    ${yarnPreinstall}

    ${lib.optionalString (ocaml_exported != null) ''
    # Copy ocaml_exported types
    chmod -R u+w .
    rsync -a ${ocaml_exported}/ ./
    chmod -R u+w .
    ''}

    # Finally, build!
    mkdir -p lib
    export NODE_ENV=${nodeEnv}

    yarn build
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    yarn test
  '';

  # The shellHook provides some functions useful when in a nix-shell
  shellHook = ''
    alias copy_nix_node_modules=${copyNixNodeModules}/bin/copy-nix-node-modules
    alias nix_yarn_install=${nixYarnInstall}/bin/nix-yarn-install
    export PATH=$(pwd)/node_modules/.bin:$PATH
    ${shellHook}
  '';

  passthru = {
    inherit
      node_modules
      ocaml_exported
      rescript
      copyNixNodeModules
      nixYarnInstall
      ;
    yarnNix = yarnNix';
  };
}
