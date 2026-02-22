{
  pkgs,
  mkShell,
  ...
}:

mkShell {
  packages = with pkgs; [
    # build
    cmake
    ninja
    clang
    lld
    llvmPackages.llvm
    gdb
    ccache
    pkg-config

    clang-tools
    cppcheck
    include-what-you-use
    doxygen
    graphviz

    # fw tooling
    platformio
    dfu-util
    picocom
    minicom
    screen

    git
    openssh
    rsync
    just
  ];

  shellHook = ''
    echo "Entered ROV default devshell (base + firmware)"
    export CC=clang
    export CXX=clang++

    export CCACHE_DIR="$PWD/.ccache"
    mkdir -p "$CCACHE_DIR"

    mkdir -p build

    echo "CMake:   cmake -S . -B build -G Ninja && cmake --build build"
    echo "FW:      cd platforms/teensy/firmware && pio run (-t upload)"
    echo "ROS:     nix develop .#ros"
  '';
}
