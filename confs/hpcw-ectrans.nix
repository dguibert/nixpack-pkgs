final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ectrans";

      package.ectrans.version = "main";
      package.ecbuild.version = "3.6.5"; # FIXME used package from spack instead of hpcw
      package.eckit.version = "1.20";
      package.fckit.version = "0.10.1";

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
