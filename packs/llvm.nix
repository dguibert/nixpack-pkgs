{packs}:
packs.default._merge (self:
    with self; {
      label = "llvm";
      package = {
        compiler =
          {extern = null;}
          // packs.default.pack.pkgs.llvm.withPrefs {version = self.package.llvm.version or null;};
      };
    })
