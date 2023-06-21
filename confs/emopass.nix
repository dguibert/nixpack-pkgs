final:
# default HPCW
pack:
pack._merge (self:
    with self; {
      label = "emopass_" + pack.label;
      package.intel-oneapi-compilers-classic.version = "2021.7.1";
      package.intel-oneapi-compilers.version = "2022.2.1";
      package.mkl.version = "2022.2.1";
      package.intel-oneapi-mpi.version = "2021.7.1";
      package.fftw.version = "3.3.10";
      package.hdf5.version = "1.12.2";
      package.netcdf-c.version = "4.9.0";
      package.netcdf-fortran.version = "4.6.0";

      package.mpi = {name = "intel-oneapi-mpi";};

      #BUILD_COMMAND ./makenemo -a BENCH -m X64_hpcw -j ${NEMO_BUILD_PARALLEL_LEVEL}
      package.nemo.variants.cfg = "BENCH";
      #error: xios dependency boost: package boost@1.72.0~atomic~chrono~clanglibcpp~container~context~contract
      #~coroutine~date_time~debug~exception~fiber~filesystem~graph~graph_parallel~icu~iostreams~json~locale~log
      # ~math~mpi+multithreaded~nowide~numpy~pic~program_options~python~random~regex~serialization+shared~signals
      #~singlethreaded~stacktrace~system~taggedlayout~test~thread~timer~type_erasure~versionedlayout~wave context-impl= cxxstd=98 visibility=hiddeni
      # does not match dependency constraints {"variants":{"atomic":true,"chrono":true,"date_time":true,"exception":true,"filesystem":true,"graph":true,"iostreams":true,"locale":true,"log":true,"math":true,"program_options":true,"random":true,"regex":true,"serialization":true,"signals":true,"system":true,"test":true,"thread":true,"timer":true,"wave":true}}
      package.boost.variants = {
        atomic = true;
        chrono = true;
        date_time = true;
        exception = true;
        filesystem = true;
        graph = true;
        iostreams = true;
        locale = true;
        log = true;
        math = true;
        program_options = true;
        random = true;
        regex = true;
        serialization = true;
        signals = true;
        system = true;
        test = true;
        thread = true;
        timer = true;
        wave = true;
      };

      # not required here but to be compliant with ifs-fvm
      package.eccodes.variants.fortran = true;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        libxml2
        xios
        cmake
        {
          pkg = nemo;
          projection = "nemo-bench/{version}";
        }
        cdo
        pkgconf # for hdf5?
      ];
    })
