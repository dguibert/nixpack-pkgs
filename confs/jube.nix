final:
# default benchmarking env with jube
pack:
pack._merge (self:
    with self; {
      label = "jube_" + pack.label;

      mod_pkgs = with self.pack.pkgs; [
        py-pyaml
        {
          pkg = jube;
          environment = {
            prepend_path = {
              JUBE_INCLUDE_PATH = "${jube.out}/share/jube/platform/slurm";
            };
          };
        }

        # for some basic tests
        mpi
        ior
      ];
    })
