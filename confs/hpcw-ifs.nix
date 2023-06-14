final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs";

      package.python2.version = "2.7.18";
      package.python2.depends.compiler = final.corePacks.pkgs.compiler;

      #package.python.version = "2";
      #package.python.variants.pythoncmd = false;
      #package.python.depends.compiler = final.corePacks.pkgs.compiler;

      #satrad/module/rttov_hdf_mod.F90(48): error #7002: Error in opening the compiled module file.  Check INCLUDE paths.   [H5ES]
      package.hdf5.version = "1.12";

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
