final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_icon";

      devShell = with final.pkgs; let
        mod_name = mod: (builtins.parseDrvName mod.name).name;
      in
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} ${mod_name self.pack.pkgs.mpi} fftw eccodes ${mod_name self.pack.pkgs.blas} cmake libxml2 ${mod_name self.pack.pkgs.szip} cdo zlib netcdf-c netcdf-fortran icon";
        };
      mods = final.mkModules label final.pkgs.corePacks mod_pkgs;

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
        cdo
        pkgconf
        icon
      ];
    })
