{
  pkgs,
  mkShell,
  ...
}:

mkShell {
  packages = with pkgs; [
    #fw tooling
    platformio

    # serial / flashing utils
    dfu-util
    picocom
    minicom
    screen

    git
    just
  ];

  shellHook = ''
    echo "Entered ROV firmware devshell"
    echo "PIO:   cd platforms/teensy/firmware && pio run"
    echo "Upload: pio run -t upload"
    echo "Serial monitor: pio device monitor  (or picocom/minicom)"
  '';
}
