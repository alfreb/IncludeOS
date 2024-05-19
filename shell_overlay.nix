{ nixpkgs ? ./pinned.nix,
  overlays ? [
    (import ./overlay.nix)
  ],
  pkgs ? import nixpkgs { config = {}; inherit overlays; }
}:
let
  inherit (pkgs) pkgsIncludeOS;
in
pkgs.mkShell {

  stdenv = pkgsIncludeOS.stdenv;

  nativeBuildInputs = [
    pkgs.nasm
    pkgs.cmake

  ];

  buildInputs = [
    pkgsIncludeOS.musl-includeos
    #pkgsIncludeOS.libcxx_parent
  ];


  shellHook = ''
    echo "Nix shell for IncludeOS development."
    echo "Validating link-time dependencies: "
    for dep in ${toString pkgsIncludeOS.linkdeps}; do
        file $dep
      done
    echo ""
    export LIBC="${pkgsIncludeOS.libc.a}"
    export LIBCXX="${pkgsIncludeOS.libcxx.a}"
    export LIBCXXABI="${pkgsIncludeOS.libcxxabi.a}"
    export LIBUNWIND="${pkgsIncludeOS.libunwind.a}"

    export CC=${pkgsIncludeOS.llvmPkgs.clang}/bin/clang
    export CXX=${pkgsIncludeOS.llvmPkgs.clang}/bin/clang++

    echo "Dependencies are exported to LIBC, LIBCXX, LIBCXXABI, LIBUNWIND"

  '';
}
