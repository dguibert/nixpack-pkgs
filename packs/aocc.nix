{packs}:
packs.default._merge (self:
    with self; {
      label = "aocc";
      package = {
        compiler = {
          name = "aocc";
          extern = null;
          version = package.aocc.version or null;
        };
        aocc.variants.license-agreed = true;
      };

      repoPatch = {
      };

      pkgs = pack: [
        {
          pkg = pack.pkgs.compiler;
        }
      ];
    })
