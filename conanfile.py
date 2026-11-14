import os
import re

from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout


class ProjectConan(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain"
    exports_sources = (
        "CMakeLists.txt",
        "VERSION",
        "src/*",
        "tests/*",
    )

    def set_name(self):
        project_name = os.path.basename(os.path.normpath(self.recipe_folder))
        if not re.fullmatch(r"[a-z][a-z0-9_]*", project_name):
            raise RuntimeError(
                f"[PROJECT CONFIG ERROR] Project directory name '{project_name}' "
                "must match ^[a-z][a-z0-9_]*$. Create the project with a lowercase "
                "name starting with a letter."
            )
        self.name = project_name

    def set_version(self):
        version_file = os.path.join(self.recipe_folder, "VERSION")
        if not os.path.isfile(version_file):
            raise RuntimeError(
                "[PROJECT CONFIG ERROR] Required project version file 'VERSION' "
                "is missing. Restore it with the project's major.minor.patch release version."
            )
        with open(version_file, encoding="utf-8") as version_source:
            project_version = version_source.read().strip()
        if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", project_version):
            raise RuntimeError(
                "[PROJECT CONFIG ERROR] 'VERSION' must contain a major.minor.patch "
                "version such as 0.1.0. Correct the project's VERSION file."
            )
        self.version = project_version

    def layout(self):
        cmake_layout(self)

    def configure(self):
        self.settings.compiler.cppstd = "23"
        if self.settings.compiler == "clang":
            self.settings.compiler.libcxx = "libstdc++11"

    def build(self):
        cmake = CMake(self)
        cmake.configure(
            variables={
                "PROJECT_NAME": self.name,
                "PROJECT_VERSION": self.version,
            }
        )
        cmake.build()

    def build_requirements(self):
        self.test_requires("gtest/1.14.0")
        self.test_requires("benchmark/1.8.3")

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.libs = [self.name]
        self.cpp_info.set_property(
            "cmake_target_name", f"{self.name}::{self.name}"
        )