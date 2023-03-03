final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs-fvm";

      package.eccodes.variants.fortran = true;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        fftw
        blas
        ecbuild
        cmake
        netcdf-c
        netcdf-fortran
        pkgconf
        perl
        cdo
        ifs-fvm
      ];
    })
