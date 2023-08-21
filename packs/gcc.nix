{packs}:
packs.default._merge (self:
    with self; {
      label = "gcc";
      package.compiler = packs.default.pack.pkgs.gcc.withPrefs {
        version = package.gcc.version or "10";
        variants.binutils = true;
      };
      package.gcc.variants.binutils = true;
      package.gcc.depends.compiler = packs.default.pack.pkgs.compiler;
    })
