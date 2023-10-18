final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_icon";

      # not required here but to be compliant with ifs-fvm
      package.eccodes.variants.fortran = true;

      #                                                                                                 "2021.6.0": "2022.1.0"
      package.intel-oneapi-compilers-classic.version = pack.package.intel-oneapi-compilers-classic.version or "2021.6.0";
      package.intel-oneapi-compilers.version = pack.package.intel-oneapi-compilers-classic.version or "2022.1.0";

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
