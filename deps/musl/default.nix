{ nixpkgs ?
  # branch nixos-20.09 @ 2021-02-20
  builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/38eaa62f28384bc5f6c394e2a99bd6a4913fc71f.tar.gz"

, pkgs ? import nixpkgs { config = {}; overlays = []; }
}:
with pkgs;
let
musl-includeos=
  stdenv.mkDerivation rec {
    pname = "musl-includeos";
    version = "1.1.18";

    src = fetchGit {
      url = "git://git.musl-libc.org/musl";
      rev = "eb03bde2f24582874cb72b56c7811bf51da0c817";
      #sha256 = "0abc123..."; 
    };

    nativeBuildInputs = [ git clang tree];

    patches = [
      ./patches/musl.patch
      ./patches/endian.patch
    ];

    postUnpack = ''  
      echo "Replacing musl's syscall headers with IncludeOS syscalls"
      # tree $sourceRoot/src

      cp ${./patches/includeos_syscalls.h} $sourceRoot/src/internal/includeos_syscalls.h
      cp ${./patches/syscall.h} $sourceRoot/src/internal/syscall.h
      
      tree $sourceRoot/src/internal
      
      rm $sourceRoot/arch/x86_64/syscall_arch.h
      rm $sourceRoot/arch/i386/syscall_arch.h           
      '';
      
    #configureFlags = [
    #  "--enable-debug"
    #  "--disable-shared"
    #];

   configurePhase = ''
      echo "Configuring with musl's configure script"
#      cd $sourceRoot
      ./configure --prefix=$out --disable-shared --enable-debug
    '';

    
    CFLAGS = "-Wno-error=int-conversion";

    installPhase = ''
    mkdir -p $out/include $out/lib
    cp -r $buildDir/musl/include/*.h $out/include/
    cp $buildDir/lib/*.a $out/lib/
    cp $buildDir/lib/*.o $out/lib/
  '';

    meta = {
      description = "musl - an implementation of the standard library for Linux-based systems";
      homepage = "https://www.musl-libc.org/";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ includeos ];
    };
  };
in
musl-includeos
