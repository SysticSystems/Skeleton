# C++23 Project Skeleton

The project name is taken from the project directory (or can be provided with ```PROJECT_NAME=<name>```), and the release version comes from ```VERSION```. Names must
match ```^[a-z][a-z0-9_]*$; ``` versions must use ```major.minor.patch``` format.

The skeleton provides a C++23 named-module library, a small importing executable, dependency-free tests, and optional Conan packaging. It requires Clang, CMake 3.28 or newer, and Ninja. Optional build settings are shown in ```.example.env;``` Conan is opt-in and remote credentials belong in the local Conan configuration, not in project files.