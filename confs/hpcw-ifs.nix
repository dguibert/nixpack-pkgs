final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_ifs";

      package.python.version = "2";
      package.python.depends.compiler = final.corePacks.pkgs.compiler;

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

        # support python 2?
        #py-pyaml
        #{
        #  pkg = jube;
        #  environment = {
        #    prepend_path = {
        #      JUBE_INCLUDE_PATH = "${jube.out}/share/jube/platform/slurm";
        #    };
        #  };
        #}

      ];
    })
