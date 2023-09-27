final: pack:
pack._merge (self:
    with self; {
      label = "ddfacet_" + pack.label;

      package.py-ddfacet.version = "git.54169950a9ba5de038a84ed8b5a65e1f1da3f918=mpi";
      # py-ddfacet dependency py-astropy: package py-astropy@5.1~all build_system=python_pip does not match dependency constraints {"version":"3.0:4.1"}
      package.py-astropy.version = "4";
      # py-astropy dependency cfitsio: package cfitsio@4.2.0+bzip2+shared build_system=autotools does not match dependency constraints {"version":":3"}
      package.cfitsio.version = "3";
      # py-numpy dependency py-cython: package py-cython@3.0.0 build_system=python_pip does not match dependency constraints {"version":"0.29.34:2"}
      package.py-setuptools.version = "57";
      package.py-numpy.version = "1.20.3";
      package.python.version = "3.9"; # ddfacet requires <3.9,>=3.0
      package.py-ipython.version = "8.11.0";
      package.py-numba.version = "0.56.4";
      package.py-llvmlite.version = "0.39";

      # as cython is a build dep only will be taken from default pack
      package.py-cython.version = "0.29.34";

      # py-astropy dependency py-pip: package py-pip@23.1.2 build_system=generic does not match dependency constraints {"version":":23.0"}
      package.py-pip.version = "23.0";

      #py-ddfacet dependency py-codex-africanus: package py-codex-africanus@0.3.4 build_system=python_pip does not match dependency constraints {"version":":0.2.10"}
      package.py-codex-africanus.version = "0.2.10";
      # py-ddfacet dependency py-dask: package py-dask@2023.4.1+array+dataframe~diagnostics+distributed bag= delayed= build_system=python_pip does not match dependency constraints {"version":"1.1.0:2021.3.0"}
      package.py-dask.version = "2020.12.0";
      # py-dask dependency py-distributed: package py-distributed@2023.4.1 build_system=python_pip does not match dependency constraints {"version":"2020.12.0:2021.8.0"}
      package.py-distributed.version = "2021.6.2";
      # py-msgpack dependency py-cython: package py-cython@3.0.0 build_system=python_pip does not match dependency constraints {"version":"0.29.30:0.29"}
      package.py-scipy.version = "1.10";
      package.py-pandas.version = "1.4";
      package.py-matplotlib.version = "3.6";
      package.py-ninja.version = "1.10.2";
      package.ninja.version = "1.10.2";
      #package.py-ninja.depends.py-ninja = self.pack.pkgs.ninja;
      package.py-blosc2.depends.py-ninja = self.pack.pkgs.py-ninja;

      package.py-meson-python.version = "0.11";
      package.py-pybind11.version = "2.10.1";
      package.py-pythran.version = "0.12";
      package.py-gast.version = "0.5.3";
      # py-ddfacet dependency py-sharedarray: package py-sharedarray@3.2.2 build_system=python_pip does not match dependency constraints {"version":"3.2.0:3.2.1"}
      package.py-sharedarray.version = "3.2.1";

      package.boost.variants.python = true;
      package.boost.variants.filesystem = true;
      package.boost.variants.system = true;
      package.casacore.variants.python = true;
      # casacore dependency wcslib: package wcslib@7.3~cfitsio~x build_system=autotools does not match dependency constraints {"variants":{"cfitsio":true},"version":"4.20:"}
      package.wcslib.variants.cfitsio = true;

      package.py-regions.version = "0.7";
      package.py-pywavelets.version = "1.1.1";

      package.llvm.variants.flang = false;
      package.llvm.version = "11";

      package.py-wheel.version = "0.37";
      # py-ddfacet dependency py-deap: package py-deap@1.3.3 build_system=python_pip does not match dependency constraints {"version":"1.0.1:1.3.1"}
      package.py-deap.version = "1.3.1";
      package.py-tables.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "62.3.2";};
      package.py-pygments.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "62.3.2";};
      package.py-cppy.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "62.3.2";};
      package.py-kiwisolver.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "62.3.2";};

      repoPatch = {
        py-regions.build.setup = ''
          os.environ['HOME'] = os.environ['TMPDIR']
        '';
        py-ddfacet = spec: old: {
          depends =
            old.depends
            // {
              py-cython.version = "0.29.34";
              py-pyfftw.version = "0.13.1";
              py-regions = null; #fails to build
            };
        };
      };

      mod_pkgs = with self.pack.pkgs; [
        compiler
        #py-numpy
        #py-cython
        #py-ddfacet
        py-mpi4py
        py-tqdm
        # ./run spack info py-ddfacet -> Build Dependencies
        py-astlib
        py-deap
        py-numpy
        py-ptyprocess
        py-pywavelets
        py-six
        py-astropy
        py-ephem
        py-pandas
        py-pybind11
        /*
        py-regions
        */
        py-tables
        py-codex-africanus
        py-ipdb
        py-pip
        py-pycpuinfo
        py-ruamel-yaml
        py-wheel
        py-configparser
        py-matplotlib
        py-polygon3
        py-pyfftw
        py-scipy
        python
        py-cython
        py-nose
        py-prettytable
        py-pylru
        py-setuptools
        py-dask
        py-numexpr
        py-psutil
        py-python-casacore
        py-sharedarray
        # ./run spack info py-ddfacet -> Link Dependencies
        py-astlib
        py-dask
        py-nose
        py-prettytable
        py-pyfftw
        py-ruamel-yaml
        py-astropy
        py-deap
        py-numexpr
        py-psutil
        py-pylru
        py-scipy
        py-codex-africanus
        py-ephem
        py-numpy
        py-ptyprocess
        py-python-casacore
        py-sharedarray
        py-configparser
        py-ipdb
        py-pandas
        py-pybind11
        py-pywavelets
        py-six
        py-cython
        py-matplotlib
        py-polygon3
        py-pycpuinfo
        /*
        py-regions
        */
        py-tables
      ];
    })
