#! /bin/bash

# Creates an locally built, editable INCLUDEOS_PACKAGE that can be passed
# to any integration test for a rapid OS development.
# The script can be called from anywhere and will create two directories:
# - build_includeos  : the local build you can rebuild with make -j install
# - includeos_package: the install target you can build a unikernel against.
#
# PS: I've tried to make all of this happen inside the nix shell for unikernels,
# but failed. If someone has a neat trick to make nix do all of this in one shell
# that might be even better.

export INCLUDEOS_SOURCE=$(realpath "${INCLUDEOS_SOURCE:-$(dirname ${BASH_SOURCE[0]})}")
export UNIKERNEL="${1:-$(realpath "$INCLUDEOS_SOURCE/example")}"


if [ ! -d "$UNIKERNEL" ]; then
  echo "👷⛔ Error: $UNIKERNEL is not a directory."
  exit 1
fi


mkdir -p includeos_package
mkdir -p build_includeos
mkdir -p build_unikernel

export INCLUDEOS_PACKAGE=$(realpath ./includeos_package)
export INCLUDEOS_BUILD=$(realpath ./build_includeos)
export UNIKERNEL_BUILD=$(realpath ./build_unikernel)

echo "👷💬 IncludeOS Source:  $INCLUDEOS_SOURCE"
echo "     IncludeOS build:   $INCLUDEOS_BUILD"
echo "     IncludeOS package: $INCLUDEOS_PACKAGE"
echo "     Unikernel:         $UNIKERNEL"
echo "     Unikernel build:   $UNIKERNEL_BUILD"


echo "👷⛏️  Making a nix build to get the full package setup"
cp -r $(nix-build $INCLUDEOS_SOURCE)/* $INCLUDEOS_PACKAGE
chmod -R u+w $INCLUDEOS_PACKAGE


echo "👷⛏️  Building IncludeOS with plain cmake, installing on top of editable package"
pushd build_includeos
nix-shell $INCLUDEOS_SOURCE/default.nix --run \
          "cmake $INCLUDEOS_SOURCE -DCMAKE_INSTALL_PREFIX=$(realpath ../includeos_package) \
          && make -j24 install"
popd

nix-shell $INCLUDEOS_SOURCE/shell.nix \
                                      --argstr buildpath $UNIKERNEL_BUILD \
                                      --argstr unikernel $UNIKERNEL \
                                      --keep INCLUDEOS_BUILD \
                                      --keep INCLUDEOS_PACKAGE \
