final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs-fvm";

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} ${(builtins.parseDrvName self.pack.pkgs.mpi.name).name} fftw ecbuild ${(builtins.parseDrvName self.pack.pkgs.blas.name).name} cmake netcdf-c netcdf-fortran";
        };
      mods = final.mkModules label final.pkgs.corePacks mod_pkgs;

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
        ifs-fvm
      ];
    })
