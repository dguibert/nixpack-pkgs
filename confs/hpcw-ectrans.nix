final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ectrans";

      package.ectrans.version = "main";

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} ${(builtins.parseDrvName self.pack.pkgs.mpi.name).name} fftw openblas cmake ectrans";
        };

      mods = final.mkModules label final.pkgs.corePacks mod_pkgs;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        fftw
        blas
        fiat
        cmake
        ectrans
      ];
    })
