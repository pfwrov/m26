add_executable(m26_controller m26_controller.cpp main.cpp)

target_link_libraries(m26_controller PRIVATE m26::m26_options m26::m26_warnings)

target_link_system_libraries(
  m26_controller
  PRIVATE
  CLI11::CLI11
  fmt::fmt
  spdlog::spdlog)

target_link_libraries(m26_controller PRIVATE SDL2::SDL2)
find_package(SDL2 REQUIRED CONFIG)

target_include_directories(m26_controller PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")
target_include_directories(m26_controller ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                                                                  $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>)
