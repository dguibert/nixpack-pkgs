final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs";

      package.python.version = "2";
      package.python.depends.compiler = final.corePacks.pkgs.compiler;
      # eccodes dependency openjpeg: package openjpeg@2.4.0~codec~ipo build_type=RelWithDebInfo does not match dependency constraints {"version":"1.5.0:1.5,2.1.0:2.3"}
      package.openjpeg.version = "2.3";
      package.openjpeg.depends.compiler = final.corePacks.pkgs.compiler;

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${package.compiler.name} ${(builtins.parseDrvName mpi.name).name} fftw
            eccodes openblas cmake python netcdf-c netcdf-fortran";
        };
      mods = with final.pkgs;
        mkModules corePacks (with self.pack.pkgs; [
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
          ifs
        ]);
    })
