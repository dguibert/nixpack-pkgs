final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ecrad";

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} fftw openblas cmake netcdf-c netcdf-fortran";
        };
      mods = with final.pkgs;
        mkModules corePacks (with self.pack.pkgs; [
          compiler
          mpi
          netcdf-c
          netcdf-fortran
          fftw
          blas
          cmake
          ecrad
        ]);
    })
