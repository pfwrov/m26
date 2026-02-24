include(GenerateExportHeader)

add_library(m26 OrderBook.cpp)

add_library(m26::m26 ALIAS m26)

target_link_libraries(m26 PRIVATE m26_options m26_warnings)

target_include_directories(m26 ${WARNING_GUARD} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                                                        $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>)

target_compile_features(m26 PUBLIC cxx_std_20)

set_target_properties(
  m26
  PROPERTIES VERSION ${PROJECT_VERSION}
             CXX_VISIBILITY_PRESET hidden
             VISIBILITY_INLINES_HIDDEN YES)

generate_export_header(m26 EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/include/m26/m26_export.hpp)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(m26 PUBLIC m26_STATIC_DEFINE)
endif()
