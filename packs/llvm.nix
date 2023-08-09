{packs}:
packs.default._merge (self:
    with self; {
      label = "llvm";
      package = {
        compiler = {
          name = "llvm";
          extern = null;
          version = package.llvm.version or null;
        };
      };
    })
