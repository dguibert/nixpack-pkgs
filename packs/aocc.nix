{packs}:
packs.default._merge (self:
    with self; {
      label = "aocc";
      package = {
        compiler = {
          name = "aocc";
          extern = null;
          version = null;
        };
        aocc.variants.license-agreed = true;
      };

      repoPatch = {
        aocc = spec: old: {
          paths = {
            cc = "bin/clang";
            cxx = "bin/clang++";
            f77 = "bin/flang";
            fc = "bin/flang";
          };
          provides =
            old.provides
            or {}
            // {
              compiler = ":";
            };
          depends =
            old.depends
            // {
              compiler = null;
            };
        };
      };

      pkgs = pack: [
        {
          pkg = pack.pkgs.compiler;
        }
      ];
    })
