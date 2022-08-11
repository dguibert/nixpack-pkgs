final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_nemo_small";

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

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          autoloads = "${package.compiler.name} ${(builtins.parseDrvName mpi.name).name}
            xios cmake";
        };
      mods = with final.pkgs;
        mkModules corePacks (with self.pack.pkgs; [
          compiler
          mpi
          xios
          cmake
          nemo
          pkgconf # for hdf5?
        ]);
    })
