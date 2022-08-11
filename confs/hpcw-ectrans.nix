final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ectrans";

      package.ectrans.version = "main";

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          autoloads = "${package.compiler.name} ${(builtins.parseDrvName mpi.name).name} fftw openblas cmake";
        };
      mods = with final.pkgs;
        mkModules corePacks (with self.pack.pkgs; [
          compiler
          mpi
          fftw
          blas
          fiat
          cmake
          ectrans
        ]);
    })
