# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class Torchfort(CMakePackage,CudaPackage):
    """An Online Deep Learning Interface for HPC programs on NVIDIA GPUs"""

    homepage = "https://github.com/NVIDIA/TorchFort"
    url = "https://github.com/NVIDIA/TorchFort/archive/refs/tags/v0.1.0.tar.gz"

    # FIXME: Add a list of GitHub accounts to
    # notify when the package is updated.
    # maintainers("github_user1", "github_user2")

    version("master", git="https://github.com/NVIDIA/TorchFort")
    version("0.1.0", sha256="0f46a07c1731cec42f8cf72a0d0ab91c550c62e6383ab33a870bae0801f64852")

    variant("examples-cpp", default=False, description="build cpp examples")
    variant("examples-fortran", default=False, description="build fortran examples")

    # FIXME: Add dependencies if required.
    depends_on("yaml-cpp~shared")
    depends_on("py-torch")
    depends_on("nvhpc") # mpi cuda nccl
    depends_on("hdf5")

    depends_on("python@3.6:")
    depends_on("py-pybind11")

    patch("torchfort-build-examples.patch")
    patch("torchfort-yamp-cpp-lib.patch")
#torch==2.0.1
#torchvision==0.15.2
#torchaudio==2.0.2
#
## training monitoring
#wandb
#
## RL example visualization related
#pygame
#moviepy
#
## Supervised learning example visualization related
#matplotlib
#h5py
    def _nvhpc_version_prefix(self):
        return join_path(self.spec['nvhpc'].prefix, "Linux_%s" % self.spec['nvhpc'].target.family, self.spec['nvhpc'].version)

    def setup_build_environment(self, env):
        nvhpc_prefix = self._nvhpc_version_prefix()
        env.set("FC",f"{nvhpc_prefix}/compilers/bin/nvfortran")

    def cmake_args(self):
        # FIXME: Add arguments other than
        # FIXME: CMAKE_INSTALL_PREFIX and CMAKE_BUILD_TYPE
        # FIXME: If not needed delete this function
        args = []
        nvhpc_prefix = self._nvhpc_version_prefix()
        args.append(self.define("NVHPC_DIR", f"{nvhpc_prefix}/cmake"))
        #args.append(self.define("NVHPC_CUDA_VERSION", f"{self.spec['cuda'].version}")) # fixme only major.minor
        args.append(self.define("NVHPC_CUDA_VERSION", f"11.8"))
        args.append(self.define("YAML_CPP_ROOT", self.spec["yaml-cpp"].prefix))
        args.append(self.define_from_variant("BUILD_EXAMPLES_CPP", "examples-cpp"))
        args.append(self.define_from_variant("BUILD_EXAMPLES_FORTRAN", "examples-fortran"))
        return args
