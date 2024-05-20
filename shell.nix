{ nixpkgs ? (import ./pinned.nix { }),
  includeos ? import ./default.nix { },
  pkgs ? nixpkgs.pkgsStatic,
  llvmPkgs ? pkgs.llvmPackages_16
}:
pkgs.mkShell rec {

  # Note the lack of pkgsStatic.
  stdenv = pkgs.llvmPackages_16.libcxxStdenv;
  vmbuild = nixpkgs.callPackage ./vmbuild.nix {};
  packages = [
    pkgs.buildPackages.cmake
    pkgs.buildPackages.nasm
    pkgs.buildPackages.llvmPackages_16.libcxxStdenv.cc
    vmbuild
  ];

  buildInputs = [
    #includeos
    #includeos.musl-includeos
    #includeos.stdenv.cc.libcxx
    pkgs.microsoft_gsl
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

    export CXX=clang++
    export CC=clang
    echo "Dependencies are export ed to LIBC, LIBCXX, LIBCXXABI, LIBUNWIND"

    rm -rf build_example
    mkdir build_example
    cd build_example
    cmake ../example -DARCH=x86_64 -DINCLUDEOS_PACKAGE=$INCLUDEOS_PACKAGE -DINCLUDEOS_LIBC_PATH=${libc} -DINCLUDEOS_LIBCXX_PATH=${libcxx} -DINCLUDEOS_LIBCXXABI_PATH=${libcxxabi} -DINCLUDEOS_LIBUNWIND_PATH=${libunwind}

    # make -j12


  '';
}
