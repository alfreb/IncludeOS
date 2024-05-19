{ nixpkgs ? (import ./pinned.nix { }),
  includeos ? import ./default.nix { },
  pkgs ? nixpkgs.pkgsStatic,
  llvmPkgs ? pkgs.llvmPackages_16
}:
pkgs.mkShell rec {

  stdenv = includeos.stdenv;
  vmbuild = nixpkgs.callPackage ./vmbuild.nix {};
  packages = [
    pkgs.buildPackages.cmake
    pkgs.buildPackages.nasm
    includeos.stdenv.cc
    includeos.stdenv.cc.libcxx
    vmbuild
  ];

  inputsFrom = [
    includeos.musl-includeos
    includeos.stdenv.cc.libcxx
  ];

  libc      = "${includeos.musl-includeos}/lib/libc.a";
  libcxx    = "${includeos.stdenv.cc.libcxx}/lib/libc++.a";
  libcxxabi = "${includeos.stdenv.cc.libcxx}/lib/libc++abi.a";
  libunwind = "${llvmPkgs.libraries.libunwind}/lib/libunwind.a";

  linkdeps = [
    libc
    libcxx
    libcxxabi
    libunwind
  ];

  shellHook = ''
    echo "Nix shell for IncludeOS development."

    if [ -z "$INCLUDEOS_PACKAGE" ]; then
        echo "INCLUDEOS_PACKAGE must be defined. It can either be a nix package or a cmake install prefix"
        exit 1
    fi

    echo "Validating link-time dependencies: "
    for dep in ${toString linkdeps}; do
        file $dep
      done
    echo ""
    export LIBC="${libc}"
    export LIBCXX="${libcxx}"
    export LIBCXXABI="${libcxxabi}"
    export LIBUNWIND="${libunwind}"

    export CXX=clang++
    export CC=clang
    echo "Dependencies are exported to LIBC, LIBCXX, LIBCXXABI, LIBUNWIND"

    rm -rf build_example
    mkdir build_example
    cd build_example
    cmake ../example -DARCH=x86_64 -DINCLUDEOS_PACKAGE=$INCLUDEOS_PACKAGE -DINCLUDEOS_LIBC_PATH=$LIBC -DINCLUDEOS_LIBCXX_PATH=$LIBCXX -DINCLUDEOS_LIBCXXABI_PATH=$LIBCXXABI -DINCLUDEOS_LIBUNWIND_PATH=$LIBUNWIND

    make -j12


  '';
}
