final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ecrad";

      package.netcdf-c.variants.mpi = false;
      package.hdf5.variants.mpi = false;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        netcdf-c
        netcdf-fortran
        cmake
        ecrad
      ];
    })
