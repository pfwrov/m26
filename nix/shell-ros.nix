{
  pkgs,
  mkShell ? pkgs.mkShell,
  ...
}:

let
  rosPkgs = pkgs.rosPackages.jazzy; # or humble

  rosEnv = rosPkgs.buildEnv {
    paths = [
      rosPkgs.ros-core

      rosPkgs.rclcpp
      rosPkgs.rclcpp-components
      rosPkgs.std-msgs
      rosPkgs.sensor-msgs
      rosPkgs.geometry-msgs
      rosPkgs.nav-msgs
      rosPkgs.tf2
      rosPkgs.tf2-ros
      rosPkgs.rcl-interfaces

      rosPkgs.ros2cli
      rosPkgs.ros2topic
      rosPkgs.ros2node
      rosPkgs.ros2param
      rosPkgs.ros2service
      rosPkgs.ros2interface
    ];
  };

  rosDistro = "jazzy"; # keep consistent with rosPkgs choice
in
mkShell {
  name = "rov-ros2-devshell";

  packages = with pkgs; [
    cmake
    ninja
    clang
    lld
    llvmPackages.llvm
    gdb
    ccache
    pkg-config
    python3
    colcon

    protobuf
    yaml-cpp

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav

    iproute2
    tcpdump
    wireshark-cli

    rosEnv
  ];

  shellHook = ''
    echo "Entered ROV ROS 2 (${rosDistro}) devshell"

    export CC=clang
    export CXX=clang++

    export CCACHE_DIR="$PWD/.ccache"
    mkdir -p "$CCACHE_DIR"

    source "${rosEnv}/setup.bash"
    export ROS_DISTRO="${rosDistro}"
    echo "Sourced ROS 2 from Nix: ${rosEnv}"
  '';
}
