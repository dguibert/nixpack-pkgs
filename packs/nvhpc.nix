{packs}: let
  target = packs.default.pack.prefs.global.target or "x86_64";
in
  packs.default._merge (self:
    with self; {
      label = "nvhpc";
      global.target =
        if target == "x86_64"
        then builtins.trace "packs/nvhpc: upgrading ${target} to x86_64_v3" "x86_64_v3"
        else target;

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

        #libbsd: has conflicts: @0.11.4: %nvhpc
        libbsd.depends.compiler = packs.default.pack.pkgs.compiler;

        # rvdv.f:187: undefined reference to `pgf90_auto_dealloc_i8'
        cdo.depends.compiler = packs.default.pack.pkgs.compiler;

        icon.variants.cuda = true;
        icon.variants.gpu = true;
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
