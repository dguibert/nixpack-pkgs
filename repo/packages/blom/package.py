# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Blom(MesonPackage):
    """Bergen Layered Ocean Model"""

    homepage = "https://github.com/NorESMhub/BLOM"
    url      = "https://github.com/NorESMhub/BLOM/archive/refs/tags/v1.2.0.tar.gz"

    version('master', git='https://github.com/NorESMhub/BLOM')
    version('1.2.0', sha256='e66e7a109f0204e44e8daf6a23a4ce74b44e0daef445581b14b9a114f2f46022')
    version('1.1.0', sha256='cf3b4e88375a0b628983f1ec8b47c3640ef5d30105d2dd0cd52d8a119abd08eb')
    version('1.0.0', sha256='4a568fc251040087f66711b4a9f3f6bde7e6af400b95591dfe048b7319de0a98')


    variant('processors',
               description='Number of processors', default=1,
               #values=tuple(list(range(1, 50000)))
               )
    variant('grid', multi=False,
            values=('gx1v5', 'gx1v6', 'gx3v7', 'tnx0.25v1', 'tnx0.25v3',
                                  'tnx0.25v4', 'tnx1.5v1', 'tnx1v1', 'tnx1v3', 'tnx1v4',
                                                   'tnx2v1', 'MNP2', 'fuk95',
                                                   'single_column','channel'),
               description='Grid name', default='fuk95')
    # Which executable driver should be built
    variant('driver', multi=False,
               values=('nocoupler', 'noforc'), default='nocoupler')
    # List of BLOM options
    variant('turbclo', multi=True,
               values=('oneeq', 'twoeq', 'advection', 'isodif'),
                      description='Turbulent closure options', default='oneeq,advection')
    variant('iage',
               description='Enable ideal age tracer', default=True)
    variant('ecosys',
               description='Enable HAMOCC as ecosystem module', default=False)
    variant('hamocc_cfc',
               description='Enable CFCs in HAMOCC', default=False)
    variant('hamocc_nattrc',
               description='Enable natural tracers in HAMOCC', default=False)
    variant('hamocc_sedbypass',
               description='Bypass sediment code in HAMOCC', default=True)
    variant('hamocc_ciso',
               description='Enable carbon isotopes in HAMOCC', default=False)
    variant('levitus2x',
               description='Enable level diagnostics at double resolution of standard Levitus depths', default=True)
    # Build configuration
    variant('openmp', default='auto', description='Enable OpenMP')
    variant('mpi', default=False, description='Enable MPI work sharing')
    variant('parallel_netcdf', default=False, description='Enable parallel version of NetCDF',
    )


    # FIXME: Add dependencies if required.
    depends_on('netcdf-fortran')
    depends_on('mpi', when='+mpi')
    depends_on('mpi', when='+parallel_netcdf')
    depends_on('parallel-netcdf', when='+parallel_netcdf')

    def meson_args(self):
        args = []

        opt_bool = lambda c, o: '-D%s=%s' % (o, str(c).lower())

        spec = self.spec

        args.append('-Dprocessors={0}'.format(get_variant_values(spec, 'processors')))
        args.append('-Dgrid={0}'.format(get_variant_values(spec, 'grid')))
        args.append('-Ddriver={0}'.format(get_variant_values(spec, 'driver')))
        args.append('-Dturbclo={0}'.format(get_variant_values(spec, 'turbclo')))
        args.append(opt_bool('+iage' in spec, 'iage'))
        args.append(opt_bool('+ecosys' in spec, 'ecosys'))
        args.append(opt_bool('+hamocc_cfc' in spec, 'hamocc_cfc'))
        args.append(opt_bool('+hamocc_nattrc' in spec, 'hamocc_nattrc'))
        args.append(opt_bool('+hamocc_sedbypass' in spec, 'hamocc_sedbypass'))
        args.append(opt_bool('+hamocc_ciso' in spec, 'hamocc_ciso'))
        args.append(opt_bool('+levitus2x' in spec, 'levitus2x'))
        args.append('-Dopenmp={0}'.format(get_variant_values(spec, 'openmp')))
        args.append(opt_bool('+mpi' in spec, 'mpi'))
        args.append(opt_bool('+parallel_netcdf' in spec, 'parallel_netcdf'))

        return args

    @run_after('build')
    def install_blom(self):
        with working_dir(self.build_directory):
          mkdir(prefix.bin)
          install('./blom', prefix.bin)

def get_variant_values(spec, name):
    value = spec.variants[name].value
    if isinstance(value, (tuple,list)):
      value = ','.join(str(v) for v in value)
    return value
