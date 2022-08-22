final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ecrad";

      package.netcdf-c.variants.mpi = false;
      package.hdf5.variants.mpi = false;

      devShell = with final.pkgs; let
        mod_name = mod: (builtins.parseDrvName mod.name).name;
      in
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} cmake netcdf-c netcdf-fortran ecrad";
        };
      mods = final.mkModules label final.pkgs.corePacks mod_pkgs;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        netcdf-c
        netcdf-fortran
        cmake
        ecrad
      ];
    })
