{ nixpkgs ? ./pinned.nix,
  overlays ? [ (import ./overlay.nix) ],
  chainloader ? (import ./chainloader.nix {}),
  pkgs ? import nixpkgs {
    config = {};
    inherit overlays;
  },
  # Will create a temp one if none is passed, for example:
  # nix-shell --argstr buildpath .
  buildpath ? "",

  # The unikernel to build
  unikernel ? "./example"
}:
pkgs.mkShell rec {
  includeos = pkgs.pkgsIncludeOS.includeos;
  stdenv = pkgs.pkgsIncludeOS.stdenv;

  vmrunner = pkgs.callPackage (builtins.fetchGit {
    url = "https://github.com/includeos/vmrunner";
  }) {};

  packages = [
    vmrunner
    stdenv.cc
    pkgs.buildPackages.cmake
    pkgs.buildPackages.nasm
  ];

  buildInputs = [
    chainloader
    pkgs.openssl
    pkgs.rapidjson
    pkgs.xorriso
  ];

  bootloader="${includeos}/boot/bootloader";

  shellHook = ''
    CC=${stdenv.cc}/bin/clang
    CXX=${stdenv.cc}/bin/clang++


    # The 'boot' utility in the vmrunner package requires these env vars
    export INCLUDEOS_VMRUNNER=${vmrunner}
    export INCLUDEOS_CHAINLOADER=${chainloader}/bin

    unikernel=$(realpath ${unikernel})
    echo -e "Attempting to build unikernel: \n$unikernel"
    if [ ! -d "$unikernel" ]; then
        echo "$unikernel is not a valid directory"
        exit 1
    fi
    export BUILDPATH=${buildpath}
    if [ -z "${buildpath}" ]; then
        export BUILDPATH=$(mktemp -d)
        pushd $BUILDPATH
    else
        mkdir -p $BUILDPATH
        pushd $BUILDPATH
    fi
    cmake $unikernel -DARCH=x86_64 -DINCLUDEOS_PACKAGE=${includeos} -DCMAKE_MODULE_PATH=${includeos}/cmake \
                     -DFOR_PRODUCTION=OFF
    make -j $NIX_BUILD_CORES
    echo -e "\n====================== IncludeOS nix-shell ====================="
    if [ -z "${buildpath}" ]; then
        echo -e "\nWorking directory, generated by this script:"
        echo $BUILDPATH
        echo -e "\nTo use another directory pass in 'buildpath' to nix:"
        echo "nix-shell --argstr buildpath you/build/path"
    fi
    echo -e "\nThe C++ compiler set to:"
    echo $(which $CXX)
    echo -e "\nIncludeOS package:"
    echo ${includeos}
  '';
}
