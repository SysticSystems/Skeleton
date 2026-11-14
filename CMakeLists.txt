cmake_minimum_required(VERSION 3.28)

if(NOT DEFINED PROJECT_NAME OR PROJECT_NAME STREQUAL "")
    get_filename_component(PROJECT_NAME "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
endif()

if(NOT PROJECT_NAME MATCHES "^[a-z][a-z0-9_]*$")
    message(FATAL_ERROR
            "Project name '${PROJECT_NAME}' must match ^[a-z][a-z0-9_]*$. "
            "Use a lowercase name starting with a letter.")
endif()

set(PROJECT_VERSION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")
if(NOT EXISTS "${PROJECT_VERSION_FILE}")
    message(FATAL_ERROR
            "Required project version file 'VERSION' is missing. "
            "Restore it with the project's major.minor.patch release version.")
endif()

file(READ "${PROJECT_VERSION_FILE}" PROJECT_VERSION)
string(STRIP "${PROJECT_VERSION}" PROJECT_VERSION)
if(NOT PROJECT_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR
            "'VERSION' must contain a major.minor.patch version such as 0.1.0. "
            "Correct the project's VERSION file.")
endif()

project(${PROJECT_NAME} VERSION ${PROJECT_VERSION} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)

if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(FATAL_ERROR
            "This template requires Clang for C++23 module support. "
            "Configure with -DCMAKE_CXX_COMPILER=clang++.")
endif()

if(NOT CMAKE_GENERATOR MATCHES "Ninja")
    message(FATAL_ERROR
            "C++ module dependency scanning requires Ninja. Configure with -G Ninja.")
endif()

option(BUILD_TESTING "Build the dependency-free test executable" OFF)
option(BUILD_BENCHMARKING "Build the benchmarking suite" OFF)

# --- Core Library Target ---
add_library(${PROJECT_NAME})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

target_sources(${PROJECT_NAME}
        PUBLIC
        FILE_SET CXX_MODULES
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/src"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/SampleModule.ixx"
)

target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src")
target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_23)
target_compile_definitions(${PROJECT_NAME} PRIVATE
        PROJECT_NAME="${PROJECT_NAME}"
        PROJECT_VERSION="${PROJECT_VERSION}"
)

# Embed source text directly into PCM artifacts for self-contained BMIs
target_compile_options(${PROJECT_NAME} PUBLIC
        "-Xclang"
        "-fmodules-embed-all-files"
)

# --- Testing Target ---
if(BUILD_TESTING)
    find_package(GTest REQUIRED)
    enable_testing()
    add_executable(${PROJECT_NAME}_tests
            "${CMAKE_CURRENT_SOURCE_DIR}/tests/exemple.cpp"
    )
    target_link_libraries(${PROJECT_NAME}_tests PRIVATE ${PROJECT_NAME}::${PROJECT_NAME} GTest::gtest GTest::gtest_main)
    target_compile_features(${PROJECT_NAME}_tests PRIVATE cxx_std_23)
    add_test(NAME ${PROJECT_NAME}_tests COMMAND ${PROJECT_NAME}_tests)
endif()

# --- Benchmarking Target ---
if(BUILD_BENCHMARKING)
    find_package(benchmark REQUIRED)
    add_executable(${PROJECT_NAME}_bench
            "${CMAKE_CURRENT_SOURCE_DIR}/bench/exemple.cpp"
    )
    target_link_libraries(${PROJECT_NAME}_bench PRIVATE ${PROJECT_NAME}::${PROJECT_NAME} benchmark::benchmark benchmark::benchmark_main)
    target_compile_features(${PROJECT_NAME}_bench PRIVATE cxx_std_23)
endif()

# --- Installation & Export Rules ---
include(GNUInstallDirs)

install(TARGETS ${PROJECT_NAME}
        EXPORT ${PROJECT_NAME}Targets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        FILE_SET CXX_MODULES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/cxx-modules
)

install(EXPORT ${PROJECT_NAME}Targets
        FILE ${PROJECT_NAME}Targets.cmake
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
        CXX_MODULES_DIRECTORY cxx-modules
)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "include(\"\${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}Targets.cmake\")\n"
)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)