final:
# default HPCW
pack:
pack._merge (self:
    with self; {
      label = "cbm2-viridian_" + pack.label;

      # samtools dependency htslib: package htslib@1.16+libcurl+libdeflate build_system=autotools does not match dependency constraints {"version":"1.17"}
      package.samtools.version = "1.16";
      package.htslib.version = "1.16";
      package.bcftools.version = "1.16";
      package.py-pysam.version = "0.19.1";

      package.py-cython.version = "0.29.34";
      package.py-setuptools.version = "63";
      # node-js dependency python: package python@3.11.6+bz2+crypt+ctypes+dbm~debug+libxml2+lzma~nis~optimizations+pic+pyexpat+pythoncmd+readline+shared+sqlite3+ssl~tkinter+uuid+zlib tix= build_system=generic does not match dependency constraints {"version":"3.6:3.10"}
      package.python.version = "3.10";
      # py-sqlalchemy dependency py-typing-extensions: package py-typing-extensions@4.8.0 build_system=python_pip does not match dependency constraints {"version":"4.2.0"}
      package.py-typing-extensions.version = "4.2.0";
      package.meson.version = "1.2.1";

      package.llvm.version = "11";
      package.swig.version = "2:4.0";

      package.py-numba.version = "0.56.4";
      package.py-llvmlite.version = "0.39";
      package.py-numpy.version = "1.23";

      package.racon.version = "1.5.0";

      mod_pkgs = with self.pack.pkgs; [
        compiler
        py-viridian-workflow
      ];
    })
