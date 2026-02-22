{
  pkgs,
  mkShell,
  ...
}:

mkShell {
  packages = with pkgs; [
    # cpp build toolchain
    cmake
    ninja
    clang
    lld
    llvmPackages.llvm
    gdb
    ccache
    pkg-config

    python3
    python3Packages.colcon-common-extensions

    protobuf
    yaml-cpp

    # camera pipelining stuff
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav

    # networking debug for surface -> pi
    iproute2
    tcpdump
    wireshark-cli
  ];

  shellHook = ''
    echo "Entered ROV ROS (C++) devshell"
    export CC=clang
    export CXX=clang++

    export CCACHE_DIR="$PWD/.ccache"
    mkdir -p "$CCACHE_DIR"

    # Auto-source ROS if installed via apt
    if [ -f /opt/ros/humble/setup.bash ]; then
      source /opt/ros/humble/setup.bash
      echo "Sourced ROS 2 Humble"
    elif [ -f /opt/ros/jazzy/setup.bash ]; then
      source /opt/ros/jazzy/setup.bash
      echo "Sourced ROS 2 Jazzy"
    else
      echo "ROS not found under /opt/ros/* (install via apt on Ubuntu if desired)."
    fi

    echo "Build (example): cd platforms/rpi/ros_ws && colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo"
  '';
}
