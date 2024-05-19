{ nixpkgs ? (import ./pinned.nix { }),
  includeos ? import ./default.nix { },
  pkgs ? nixpkgs.pkgsStatic,
  llvmPkgs ? pkgs.llvmPackages_16
}:

includeos.stdenv.mkDerivation rec {
  pname = "includeos_example";
  src = pkgs.lib.cleanSource ./example;
  doCheck = false;
  dontStrip = true;

  vmbuild = nixpkgs.callPackage ./vmbuild.nix {};

  nativeBuildInputs = [
    pkgs.buildPackages.nasm
    pkgs.buildPackages.cmake
    vmbuild
  ];

  buildInputs = [
    pkgs.microsoft_gsl
    includeos
  ];

  bootloader = "${includeos}/boot/bootloader";

  # TODO:
  # We currently need to explicitly pass in because we link with a linker script
  # and need to control linking order.
  # This can be moved to os.cmake eventually, once we figure out how to expose
  # them to cmake from nix without having to make cmake depend on nix.
  # * Maybe we should make symlinks from the includeos package to them.

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

  cmakeFlags = [
    "-DINCLUDEOS_PACKAGE=${includeos}"
    "-DINCLUDEOS_LIBC_PATH=${libc}"
    "-DINCLUDEOS_LIBCXX_PATH=${libcxx}"
    "-DINCLUDEOS_LIBCXXABI_PATH=${libcxxabi}"
    "-DINCLUDEOS_LIBUNWIND_PATH=${libunwind}"

    "-DARCH=x86_64"
    "-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"
  ];

  preBuild = ''
    echo ""
    echo "📣 preBuild: about to build - can it work?  Yes! 🥁🥁🥁"
    echo "Validating dependencies: "
    for dep in ${toString linkdeps}; do
        echo "Checking $dep:"
        file $dep
      done
    echo ""
  '';


  vmbuild_executable = "${vmbuild}/bin/vmbuild";
  elfsyms_executable = "${vmbuild}/bin/elf_syms";
  example_executable = "$out/bin/hello_includeos.elf.bin";
  image_name = "hello_includeos.elf.bin.img";

  postBuild = ''
    echo "🎉 POST BUILD - you made it pretty far! 🗻⛅"
    echo "Verifying image building tools: "
    echo "- vmbuild:    ${vmbuild_executable}"
    echo "- vmbuild:    ${elfsyms_executable}"
    echo "- example:    ${example_executable}"
    echo "- bootloader: ${bootloader}"
  '';

    # echo "Running elf_syms:"
    # ${elfsyms_executable} ${example_executable}
    # echo "Running vmbuild:"
    # ${vmbuild_executable} ${example_executable} ${bootloader}
    # echo "Vmbuild exit status:  $?"
    # ls -lah $out <- this fails. Not available in postBuild?
    # file ./${image_name}
    # cp ${image_name} $out/${image_name}
    # echo "Image copied to: "
    # file $out/${image_name}

  version = "dev";
}
