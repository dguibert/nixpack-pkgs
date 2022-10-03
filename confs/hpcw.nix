final:
# default HPCW
pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label;
      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
      ];
    })
