# M26 – Explorer ROV

## Development Environment (Recommended)

We use Nix to provide reproducible development environments.

Default (C++ + Firmware) `nix develop`

ROS Development `nix develop .#ros`

Firmware Only `nix develop .#fw`

## Getting Started

- [Dependency Setup](README_dependencies.md)
- [Building Details](README_building.md)

## Testing

See
[Catch2 tutorial](https://github.com/catchorg/Catch2/blob/master/docs/tutorial.md)

## Fuzz testing

See
[libFuzzer Tutorial](https://github.com/google/fuzzing/blob/master/tutorial/libFuzzerTutorial.md)
