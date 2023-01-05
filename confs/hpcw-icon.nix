final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_icon";

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        blas
        libxml2
        zlib
        eccodes
        cmake
        netcdf-c
        netcdf-fortran
        szip
        #cdo
        pkgconf
        #        icon
      ]
      ++ final.lib.optionals (self.package.icon.variants.gpu) [
        cuda
      ]
      ;
      builtin_pkgs = with self.pack.pkgs; [cdo];
    })
