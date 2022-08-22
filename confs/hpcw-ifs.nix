final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs";

      package.python.version = "2";
      package.python.depends.compiler = final.corePacks.pkgs.compiler;

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} ${(builtins.parseDrvName self.pack.pkgs.mpi.name).name} fftw eccodes openblas cmake python netcdf-c netcdf-fortran ifs";
        };
      mods = final.mkModules label final.pkgs.corePacks mod_pkgs;

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
