include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)

include(CheckCXXSourceCompiles)

macro(m26_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if(NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(m26_setup_options)
  option(m26_ENABLE_HARDENING "Enable hardening" ON)
  option(m26_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    m26_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    m26_ENABLE_HARDENING
    OFF)

  m26_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR m26_PACKAGING_MAINTAINER_MODE)
    option(m26_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(m26_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(m26_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(m26_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(m26_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(m26_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(m26_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(m26_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(m26_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(m26_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(m26_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(m26_ENABLE_PCH "Enable precompiled headers" OFF)
    option(m26_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(m26_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(m26_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(m26_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(m26_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(m26_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(m26_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(m26_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(m26_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(m26_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(m26_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(m26_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(m26_ENABLE_PCH "Enable precompiled headers" OFF)
    option(m26_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      m26_ENABLE_IPO
      m26_WARNINGS_AS_ERRORS
      m26_ENABLE_USER_LINKER
      m26_ENABLE_SANITIZER_ADDRESS
      m26_ENABLE_SANITIZER_LEAK
      m26_ENABLE_SANITIZER_UNDEFINED
      m26_ENABLE_SANITIZER_THREAD
      m26_ENABLE_SANITIZER_MEMORY
      m26_ENABLE_UNITY_BUILD
      m26_ENABLE_CLANG_TIDY
      m26_ENABLE_CPPCHECK
      m26_ENABLE_COVERAGE
      m26_ENABLE_PCH
      m26_ENABLE_CACHE)
  endif()

  m26_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED
     AND (m26_ENABLE_SANITIZER_ADDRESS
          OR m26_ENABLE_SANITIZER_THREAD
          OR m26_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(m26_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(m26_global_options)
  if(m26_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    m26_enable_ipo()
  endif()

  m26_supports_sanitizers()

  if(m26_ENABLE_HARDENING AND m26_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN
       OR m26_ENABLE_SANITIZER_UNDEFINED
       OR m26_ENABLE_SANITIZER_ADDRESS
       OR m26_ENABLE_SANITIZER_THREAD
       OR m26_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${m26_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${m26_ENABLE_SANITIZER_UNDEFINED}")
    m26_enable_hardening(m26_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(m26_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(m26_warnings INTERFACE)
  add_library(m26_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  m26_set_project_warnings(
    m26_warnings
    ${m26_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(m26_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    m26_configure_linker(m26_options)
  endif()

  include(cmake/Sanitizers.cmake)
  m26_enable_sanitizers(
    m26_options
    ${m26_ENABLE_SANITIZER_ADDRESS}
    ${m26_ENABLE_SANITIZER_LEAK}
    ${m26_ENABLE_SANITIZER_UNDEFINED}
    ${m26_ENABLE_SANITIZER_THREAD}
    ${m26_ENABLE_SANITIZER_MEMORY})

  set_target_properties(m26_options PROPERTIES UNITY_BUILD ${m26_ENABLE_UNITY_BUILD})

  if(m26_ENABLE_PCH)
    target_precompile_headers(
      m26_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(m26_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    m26_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(m26_ENABLE_CLANG_TIDY)
    m26_enable_clang_tidy(m26_options ${m26_WARNINGS_AS_ERRORS})
  endif()

  if(m26_ENABLE_CPPCHECK)
    m26_enable_cppcheck(${m26_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(m26_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    m26_enable_coverage(m26_options)
  endif()

  if(m26_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(m26_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(m26_ENABLE_HARDENING AND NOT m26_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN
       OR m26_ENABLE_SANITIZER_UNDEFINED
       OR m26_ENABLE_SANITIZER_ADDRESS
       OR m26_ENABLE_SANITIZER_THREAD
       OR m26_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    m26_enable_hardening(m26_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
