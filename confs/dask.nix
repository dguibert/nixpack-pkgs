final:
# default benchmarking env with jube
pack:
pack._merge (self:
    with self; {
      label = "dask_" + pack.label;

      # py-jupyterlab dependency py-jinja2: package py-jinja2@3.1.2~i18n build_system=python_pip does not match dependency constraints {"version":"3.0.3"}
      package.py-jinja2.version = "3.0.3";
      # py-jupyter-events dependency py-jsonschema: package py-jsonschema@4.17.3~format-nongpl build_system=python_pip does not match dependency constraints {"variants":{"format-nongpl":true},"version":"3.2:"}
      package.py-jsonschema.variants.format-nongpl = true;
      package.py-cython.version = "0.29.35";
      package.py-pyyaml.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pandas.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-setuptools.version = "63";
      package.py-numpy.depends.py-cython = self.pack.pkgs.py-cython;

      package.llvm.variants.flang = false;
      package.llvm.version = "14";
      package.swig.version = "4.0";
      package.py-numpy.version = "1.24";
      package.arrow.variants.python = true;

      package.boost.variants.python = true;
      package.boost.variants.filesystem = true;
      package.boost.variants.system = true;

      package.python.version = "3.9"; # boost

      package.re2.variants.shared = true;
      package.snappy.variants.shared = false;
      package.utf8proc.variants.shared = true;
      package.utf8proc.variants.version = "2.7.0";

      package.py-pip.version = "23.0";
      package.py-aiobotocore.version = "2.4";
      package.py-botocore.version = "1.27.59";
      package.py-fsspec.version = "2022.11.0";
      package.py-pyarrow.depends.py-pip = self.pack.pkgs.py-pip;
      package.py-scipy.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pythran.version = "0.12";
      package.py-scipy.depends.py-pythran = self.pack.pkgs.py-pythran;
      package.py-gast.version = "0.5.3";

      package.py-gevent.version = "1.5";
      package.py-pybind11.version = "2.10";
      package.py-msgpack.depends.py-cython = self.pack.pkgs.py-cython;

      repoPatch = {
        py-distributed = spec: old: {
          depends =
            old.depends
            // {
              py-jinja2.version = "3.0.3";
              py-tornado.version = "6.2";
            };
        };
        py-gevent = spec: old: {
          depends =
            old.depends
            // {
              python.version = "3.9";
            };
        };
      };

      mod_pkgs = with self.pack.pkgs; [
        # ipycytoscape # https://github.com/cytoscape/ipycytoscape
        # dask-labextension # https://github.com/dask/dask-labextension
        py-jupyterlab
        py-graphviz
        py-matplotlib
        py-zarr
        py-xarray
        py-pooch
        py-pyarrow
        py-s3fs
        py-scipy
        py-dask
        py-distributed
      ];
    })
