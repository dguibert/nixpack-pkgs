final: pack:
pack._merge (self:
    with self; {
      label = "ddfacet_" + pack.label;

      # py-ddfacet dependency py-astropy: package py-astropy@5.1~all build_system=python_pip does not match dependency constraints {"version":"3.0:4.1"}
      package.py-astropy.version = "4";
      # py-astropy dependency cfitsio: package cfitsio@4.2.0+bzip2+shared build_system=autotools does not match dependency constraints {"version":":3"}
      package.cfitsio.version = "3";
      # py-numpy dependency py-cython: package py-cython@3.0.0 build_system=python_pip does not match dependency constraints {"version":"0.29.34:2"}
      package.py-numpy.version = "1.19.5";
      package.python.version = "3.9";
      package.py-numba.version = "0.56.4";
      package.py-llvmlite.version = "0.39";

      # as cython is a build dep only will be taken from default pack
      package.py-numpy.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-cython.version = "0.29.34";

      # py-astropy dependency py-pip: package py-pip@23.1.2 build_system=generic does not match dependency constraints {"version":":23.0"}
      package.py-pip.version = "23.0";
      package.py-astropy.depends.py-pip = self.pack.pkgs.py-pip;

      #py-ddfacet dependency py-codex-africanus: package py-codex-africanus@0.3.4 build_system=python_pip does not match dependency constraints {"version":":0.2.10"}
      package.py-codex-africanus.version = "0.2.10";
      # py-ddfacet dependency py-dask: package py-dask@2023.4.1+array+dataframe~diagnostics+distributed bag= delayed= build_system=python_pip does not match dependency constraints {"version":"1.1.0:2021.3.0"}
      package.py-dask.version = "2020.12.0";
      # py-dask dependency py-distributed: package py-distributed@2023.4.1 build_system=python_pip does not match dependency constraints {"version":"2020.12.0:2021.8.0"}
      package.py-distributed.version = "2021.6.2";
      # py-msgpack dependency py-cython: package py-cython@3.0.0 build_system=python_pip does not match dependency constraints {"version":"0.29.30:0.29"}
      package.py-msgpack.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pyyaml.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pandas.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pyfftw.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-scipy.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-scipy.version = "1.10";
      package.py-pandas.version = "1.4";
      package.py-matplotlib.version = "3.6";

      package.py-scipy.depends.py-meson-python = self.pack.pkgs.py-meson-python;
      package.py-meson-python.version = "0.11";
      package.py-pybind11.version = "2.10.1";
      package.py-pythran.version = "0.12";
      package.py-scipy.depends.py-pythran = self.pack.pkgs.py-pythran;
      package.py-gast.version = "0.5.3";
      # py-ddfacet dependency py-sharedarray: package py-sharedarray@3.2.2 build_system=python_pip does not match dependency constraints {"version":"3.2.0:3.2.1"}
      package.py-sharedarray.version = "3.2.1";

      package.boost.variants.python = true;
      package.boost.variants.filesystem = true;
      package.boost.variants.system = true;
      package.casacore.variants.python = true;
      # casacore dependency wcslib: package wcslib@7.3~cfitsio~x build_system=autotools does not match dependency constraints {"variants":{"cfitsio":true},"version":"4.20:"}
      package.wcslib.variants.cfitsio = true;

      package.py-regions.version = "0.5";
      package.py-pywavelets.version = "1.1.1";
      package.py-pywavelets.depends.py-setuptools = self.pack.pkgs.py-setuptools;

      package.llvm.variants.flang = false;
      package.llvm.version = "11";
      package.py-setuptools.version = "57";

      # py-ddfacet dependency py-deap: package py-deap@1.3.3 build_system=python_pip does not match dependency constraints {"version":"1.0.1:1.3.1"}
      package.py-deap.version = "1.3.1";
      package.py-deap.depends.py-setuptools = self.pack.pkgs.py-setuptools;

      package.py-nose.depends.py-setuptools = self.pack.pkgs.py-setuptools;

      package.py-pygments.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "62.3.2";};

      repoPatch = {
        py-ddfacet = spec: old: {
          depends =
            old.depends
            // {
              py-cython.version = "0.29.34";
            };
        };
      };

      mod_pkgs = with self.pack.pkgs; [
        compiler
        #py-numpy
        #py-cython
        py-ddfacet
      ];
    })
