{packs}:
packs.default._merge (self:
    with self; {
      label = "intel";
      repoPatch = {
        intel-oneapi-compilers-classic = spec: old: {
          compiler_spec = "intel"; # can be overridden as "intel" with prefs
          provides =
            old.provides
            or {}
            // {
              compiler = ":";
            };
        };
      };
      package = {
        compiler = {
          name = "intel-oneapi-compilers-classic";
          extern = null;
          #version = null;
          version = package.intel-oneapi-compilers-classic.version or null;
        };
        intel-oneapi-compilers-classic.depends.compiler = packs.default.pack.pkgs.compiler;
        intel-oneapi-compilers.depends.compiler = packs.default.pack.pkgs.compiler;

        #intel-oneapi-compilers-classic dependency intel-oneapi-compilers: package intel-oneapi-compilers@2023.2.1+envmods build_system=generic does not match dependency constraints {"version":"2023.2.0"}

        # with @2024:, icc and icpx have been discontinued
        intel-oneapi-compilers.version = "2023.2.0";
        intel-oneapi-compilers-classic.version = "2021.10.0";

        # /dev/shm/nix-build-ucx-1.11.2.drv-0/bguibertd/spack-stage-ucx-1.11.2-p4f833gchjkggkd1jhjn4rh93wwk2xn5/spack-src/src/ucs/datastruct/linear_func.h:147:21: error: comparison with infinity always evaluates to false in fast floating point mode> if (isnan(x) || isinf(x))
        #ucx.depends.compiler = packs.default.pack.pkgs.compiler;
      };

      pkgs = pack: [
        {
          pkg = pack.pkgs.compiler;
        }
      ];
    })
