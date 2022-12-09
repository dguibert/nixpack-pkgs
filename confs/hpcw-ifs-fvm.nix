final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs-fvm";

      package.eccodes.variants.fortran = true;
      package.ecbuild.version = "3.6.1";
      # ecbuild dependency cmake: package cmake@3.25.0~doc+ncurses+ownlibs~qt build_system=generic build_type=Release does not match dependency constraints {"version":"3.11:3.19"}
      package.cmake.version = "3.19";

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
