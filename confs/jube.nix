final:
# default benchmarking env with jube
pack:
pack._merge (self:
    with self; {
      label = "jube_" + pack.label;

      mod_pkgs = with self.pack.pkgs; [
        py-pyaml
        jube
      ];
    })
