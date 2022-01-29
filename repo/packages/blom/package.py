# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Blom(MesonPackage):
    """Bergen Layered Ocean Model"""

    homepage = "https://github.com/NorESMhub/BLOM"
    url      = "https://github.com/NorESMhub/BLOM/archive/refs/tags/v1.2.0.tar.gz"

    version('1.2.0', sha256='e66e7a109f0204e44e8daf6a23a4ce74b44e0daef445581b14b9a114f2f46022')
    version('1.1.0', sha256='cf3b4e88375a0b628983f1ec8b47c3640ef5d30105d2dd0cd52d8a119abd08eb')
    version('1.0.0', sha256='4a568fc251040087f66711b4a9f3f6bde7e6af400b95591dfe048b7319de0a98')

    variant('mpi', default=True, description='Enable MPI support')
    variant(
        "pnetcdf",
        default=True,
        description="Parallel IO support through Pnetcdf library",
    )


    # FIXME: Add dependencies if required.
    depends_on('netcdf-fortran')
    depends_on('mpi', when='+mpi')
    depends_on("parallel-netcdf", when="+pnetcdf")

    def meson_args(self):
        args = []
        if '+mpi' in self.spec:
          args.append('-Dmpi=true')
        else:
          args.append('-Dmpi=false')
        if '+pnetcdf' in self.spec:
          args.append('-Dparallel_netcdf=true')
        else:
          args.append('-Dparallel_netcdf=false')

        return args

    @run_after('build')
    def install_blom(self):
        with working_dir(self.build_directory):
          mkdir(prefix.bin)
          install('./blom', prefix.bin)
