final:
# default benchmarking env with jube
pack:
pack._merge (self:
    with self; {
      label = "reframe_" + pack.label;

      package.py-charset-normalizer.version = "2.0";
      mod_pkgs = with self.pack.pkgs; [
        reframe
      ];
    })
