final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs";

      package.python2.version = "2.7.18";
      package.python2.depends.compiler = final.corePacks.pkgs.compiler;

      #package.python.version = "2";
      #package.python.variants.pythoncmd = false;
      #package.python.depends.compiler = final.corePacks.pkgs.compiler;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        fftw
        blas
        python
        eccodes
        cmake
        netcdf-c
        netcdf-fortran
        szip
        pkgconf
        ifs
      ];
    })
