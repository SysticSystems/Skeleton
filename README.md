# C++23 Project Skeleton

This repository is a starter template for a modern C++ project built around a Clang C++23 module library. It is intended to run with Systic Synapse, which builds and runs the project inside an OCI container to keep development tools and dependencies isolated from the host. Conan is part of the required dependency/build workflow.

## What this template gives you

- A CMake project configured for Clang + Ninja
- A named module library in `src/`
- A placeholder test target in `tests/`
- A placeholder benchmark target in `bench/`
- A `VERSION` file that drives the release number
- Conan dependency management via `conanfile.py`
- Containerized builds through Systic Synapse

## Tailoring this template to your project

### 1. Rename the project identity

The project name is inferred from the folder name by default, or you can force it with:

```bash
PROJECT_NAME=my_project
```

The project name must match:

```text
^[a-z][a-z0-9_]*$
```

This means:

- lowercase only
- must start with a letter
- underscores are allowed
- no uppercase letters, dashes, or spaces

Update the `VERSION` file to your own release number:

```text
0.1.0
```

The version must use `major.minor.patch` format.

### 2. Replace the sample module

The default library source is:

```text
src/SampleModule.ixx
```

Rename it and replace its contents with your own module interface. For example:

```text
src/math.ixx
src/network.ixx
src/project_core.ixx
```

Then update `CMakeLists.txt` so the library points at your new file:

```cmake
target_sources(${PROJECT_NAME}
        PUBLIC
        FILE_SET CXX_MODULES
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/src"
        FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/your_module.ixx"
)
```

Keep the module name consistent with your public API and exports.

### 3. Update the library API

The starter module defines a sample class that throws a placeholder runtime error. Replace it with your actual domain types or interfaces:

```cpp
export module MyProjectCore;

export class Calculator {
public:
    int add(int a, int b) const;
};
```

This is the place to define:

- public interfaces
- reusable utilities
- domain models
- business logic modules

### 4. Customize the tests

The basic test file is here:

```text
tests/exemple.cpp
```

Replace it with your own test suite using GTest. Keep the same target name if you want the default build flow to keep working:

```cmake
if(BUILD_TESTING)
    find_package(GTest REQUIRED)
    enable_testing()
    add_executable(${PROJECT_NAME}_tests
            "${CMAKE_CURRENT_SOURCE_DIR}/tests/exemple.cpp"
    )
    target_link_libraries(${PROJECT_NAME}_tests PRIVATE ${PROJECT_NAME}::${PROJECT_NAME} GTest::gtest GTest::gtest_main)
    add_test(NAME ${PROJECT_NAME}_tests COMMAND ${PROJECT_NAME}_tests)
endif()
```

Use tests to cover:

- public API contracts
- edge cases
- failure conditions
- performance-sensitive behavior when relevant

### 5. Customize the benchmark target

The benchmarking example lives in:

```text
bench/exemple.cpp
```

Replace it with a benchmark for the real hot paths in your project. The default build flow will still work if you keep the target name `${PROJECT_NAME}_bench`.

### 6. Review local build settings

The project includes a local example environment file:

```text
.example.env
```

It can be copied or adapted for local development:

```bash
cp .example.env .env
```

The environment settings are consumed by Synapse. Conan is required for the project workflow; do not disable it.

### 7. Adjust install and export rules

The `CMakeLists.txt` includes installation/export rules for the library and its C++ module files. These are useful for packaging your project as a library or consuming it from other CMake projects.

If your project is not intended to be installed, you can simplify this section. If it is, keep the export target and install locations aligned with your package structure.

### 8. Refresh the repository metadata

Before using the project in production, update the following:

- `LICENSE` if the default license is not correct
- `.gitignore` if you need project-specific generated files
- CI config under `.github/`
- any documentation or developer scripts referencing the sample module name

### 9. Keep the template conventions clean

A good project migration usually means:

- renaming `SampleModule` references
- removing placeholder `run()` logic
- replacing example tests and benchmarks
- cleaning up unused packaging or environment settings
- aligning the module names with your real domain model

## Coding style and static analysis

Follow the repository's `clang-format` configuration when formatting C++ code. It uses four-column indentation, same-line braces, a 100-character line limit, and sorted, grouped includes. Run `clang-format` with this config when editing or adding C++ files.

The `.clang-tidy` configuration enables bug-prone, correctness, performance, and readability checks, including the project's identifier naming conventions. It treats all enabled diagnostics as errors. Run `clang-tidy` with the build's compilation database and address reported diagnostics when changing C++ code.

## Build with Systic Synapse

Run these commands from the project root. The first builds the OCI development image; the second runs the build inside that container:

```bash
./synapse.sh create
./synapse.sh run --type=relwithdebinfo
```

Synapse wraps development execution in a container so the required toolchain and dependencies do not need to be installed directly on the host. The `run` command accepts the build type with `--type`; for example, use `release` or `debug` instead of `relwithdebinfo` when appropriate.

You need Podman or Docker available to create and run the OCI container.

## Notes
- This template expects Clang and CMake 3.28+.
- It requires Ninja because C++ module dependency scanning is enabled.
- The project is intentionally minimal: the goal is to give you a clean starting point rather than a finished product.

Use this README as the blueprint for replacing the sample placeholders with your actual project structure and module API. Continue to use `./synapse.sh create` and `./synapse.sh run --type=...` for the containerized development workflow.
