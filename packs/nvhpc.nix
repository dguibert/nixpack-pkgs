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

        py-kiwisolver.depends.compiler = packs.default.pack.pkgs.compiler;
        py-protobuf.depends.compiler = packs.default.pack.pkgs.compiler;
        py-pillow.depends.compiler = packs.default.pack.pkgs.compiler;
        py-cython.depends.compiler = packs.default.pack.pkgs.compiler;
        py-numpy.depends.compiler = packs.default.pack.pkgs.compiler;
        py-numexpr.depends.compiler = packs.default.pack.pkgs.compiler;
        py-bottleneck.depends.compiler = packs.default.pack.pkgs.compiler;
        py-contourpy.depends.compiler = packs.default.pack.pkgs.compiler;
        py-scipy.depends.compiler = packs.default.pack.pkgs.compiler;
        py-matplotlib.depends.compiler = packs.default.pack.pkgs.compiler;
        valgrind.depends.compiler = packs.default.pack.pkgs.compiler;
        py-llvmlite.depends.compiler = packs.default.pack.pkgs.compiler;
        py-numba.depends.compiler = packs.default.pack.pkgs.compiler;
        py-pandas.depends.compiler = packs.default.pack.pkgs.compiler;
        py-torch.depends.compiler = packs.default.pack.pkgs.compiler;
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
