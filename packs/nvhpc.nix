{packs}:
packs.default._merge (self:
    with self; {
      label = "nvhpc";
      package = {
        compiler = {
          name = "nvhpc";
          extern = null;
          version = package.nvhpc.version or null;
        };
        #nvhpc.version = "22.7";
        nvhpc.variants.blas = false;
        nvhpc.variants.lapack = false;
        nvhpc.depends.compiler = packs.default.pack.pkgs.compiler;

        eckit.depends.compiler = packs.default.pack.pkgs.compiler;
      };

      repoPatch = {
        nvhpc = spec: old: {
          provides =
            old.provides
            or {}
            // {
              compiler = ":";
            };
          conflicts = [];
        };
      };

      pkgs = pack: [
        {
          pkg = pack.pkgs.compiler;
        }
      ];
    })
