final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_nemo_medium";

      #BUILD_COMMAND ./makenemo -m X64_hpcw -n MY_ORCA25 -r ORCA2_ICE_PISCES  -j ${NEMO_BUILD_PARALLEL_LEVEL} del_key "key_top" add_key "key_si3  key_iomput key_mpp_mpi key_mpi2"
      package.nemo.variants.cfg = "ORCA2_ICE_PISCES";
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
          projection = "nemo-orca2_ice_pisces/{version}";
        }
        cdo
        pkgconf # for hdf5?
      ];

      img_pkgs = with self.pack.pkgs; [
        mpi
        nemo
        cdo
      ];
    })
