final: pack:
pack._merge (self:
    with self; {
      label = "ddfacet_exp_" + pack.label;

      package.py-ddfacet.version = "git.54169950a9ba5de038a84ed8b5a65e1f1da3f918=mpi";
      # py-ddfacet dependency py-astropy: package py-astropy@5.1~all build_system=python_pip does not match dependency constraints {"version":"3.0:4.1"}
      package.py-astropy.version = "4";
      # py-astropy dependency cfitsio: package cfitsio@4.2.0+bzip2+shared build_system=autotools does not match dependency constraints {"version":":3"}
      package.cfitsio.version = "3";
      package.py-pip.version = "23.0";
      package.py-numba.version = "0.58";
      package.py-numpy.version = "1.26.2";
      package.python.version = "3.11"; # ddfacet requires <3.9,>=3.0
      package.py-ipython.version = "8.11.0";

      #py-ddfacet dependency py-codex-africanus: package py-codex-africanus@0.3.4 build_system=python_pip does not match dependency constraints {"version":":0.2.10"}
      package.py-codex-africanus.version = "0.2.10";
      package.py-distributed.version = "2023.4.1";
      package.py-tornado.version = "6.1";
      package.py-versioneer.version = "0.28";
      # py-msgpack dependency py-cython: package py-cython@3.0.0 build_system=python_pip does not match dependency constraints {"version":"0.29.30:0.29"}
      package.py-matplotlib.version = "3.6";
      package.py-ninja.version = "1.10.2";
      package.ninja.version = "1.10.2";
      #package.py-ninja.depends.py-ninja = self.pack.pkgs.ninja;
      package.py-blosc2.depends.py-ninja = self.pack.pkgs.py-ninja;

      package.py-meson-python.version = "0.13.1";
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

      package.py-tables.version = "3.7.0";
      package.py-regions.version = "0.5";
      package.py-pywavelets.version = "1.1.1";

      package.llvm.variants.flang = false;
      package.llvm.version = "14";

      package.py-llvmlite.version = "0.41";

      package.py-wheel.version = "0.37";
      # py-ddfacet dependency py-deap: package py-deap@1.3.3 build_system=python_pip does not match dependency constraints {"version":"1.0.1:1.3.1"}
      package.py-deap.version = "1.3.1";
      package.py-tables.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "68.0.0";};
      package.py-pygments.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "68.0.0";};
      package.py-cppy.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "68.0.0";};
      package.py-kiwisolver.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "68.0.0";};
      package.py-kiwisolver.version = "1.3.2";
      package.swig.version = "4.0";
      package.py-tqdm.version = "4.66.1";

      package.py-donfig.version = "0.7.0";

      package.py-pandas.depends.py-cython = self.pack.pkgs.py-cython.withPrefs {version = "0.29.36";};
      package.py-msgpack.depends.py-cython = self.pack.pkgs.py-cython.withPrefs {version = "0.29.36";};
      package.py-pyyaml.depends.py-cython = self.pack.pkgs.py-cython.withPrefs {version = "0.29.36";};

      package.py-numpy.depends.py-pip = self.pack.pkgs.py-pip.withPrefs {version = "23.1";};

      package.snappy.variants.shared = false;
      package.py-arrow.version = "14.0.1";
      package.arrow.version = package.py-arrow.version;
      package.arrow.variants.python = true;
      package.re2.variants.shared = true;
      package.utf8proc.version = "2.7.0";
      package.utf8proc.variants.shared = true;

      # py-cachecontrol@0.12.11~filecache build_system=python_pip does not match dependency constraints {"variants":{"filecache":true},"version":"0.12.9:0.12"}
      package.py-cachecontrol.variants.filecache = true;
      package.py-cleo.version = "1";
      package.py-rapidfuzz.version = "2";
      package.py-scikit-build.version = "0.15.0";
      package.py-platformdirs.version = "2";
      package.py-poetry-core.version = "1.2.0";
      package.py-requests-toolbelt.version = "0.9";
      package.py-urllib3.version = "1";

      package.py-poetry.depends.py-crashtest = self.pack.pkgs.py-crashtest.withPrefs {version = "0.3";};
      package.py-virtualenv.depends.py-platformdirs = self.pack.pkgs.py-platformdirs.withPrefs {version = "3";};

      repoPatch = {
        py-regions.build.setup = ''
          os.environ['HOME'] = os.environ['TMPDIR']
        '';
        py-pyarrow.build.setup = ''
          os.environ['SOURCE_DATE_EPOCH']='315532800'
        '';
        py-ddfacet = spec: old: {
          depends =
            old.depends
            // {
              py-cython.version = "0.29.34";
              py-pyfftw.version = "0.13.1";
            };
        };
      };

      mod_pkgs = with self.pack.pkgs; [
        compiler
        py-ipython
        #py-numpy
        #py-cython
        #py-ddfacet
        py-mpi4py
        py-numba
        py-xarray
        py-dask
        py-numpy
        py-dask-ms
      ];
    })
