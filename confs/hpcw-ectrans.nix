final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ectrans";

      package.ectrans.version = "main";

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
