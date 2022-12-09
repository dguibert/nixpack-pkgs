{packs}:
packs.default._merge (self:
    with self; {
      label = "intel";
      repoPatch = {
        intel-oneapi-compilers = spec: old: {
          compiler_spec = "intel"; # can be overridden as "intel" with prefs
          paths = {
            cc = "compiler/latest/linux/bin/intel64/icc";
            cxx = "compiler/latest/linux/bin/intel64/icpc";
            f77 = "compiler/latest/linux/bin/intel64/ifort";
            fc = "compiler/latest/linux/bin/intel64/ifort";
          };
          provides =
            old.provides
            or {}
            // {
              compiler = ":";
            };
          build = {
            post = ''
              # remove installer cache/packagemanager and broken links to pythonpackages
              shutil.rmtree(f"{spec.prefix}/intel", ignore_errors=True)
            '';
          };
        };
      };
      package = {
        compiler = {
          name = "intel-oneapi-compilers";
          extern = null;
          version = null;
        };
        intel-oneapi-compilers.depends.compiler = packs.default.pack.pkgs.compiler;
        # /dev/shm/nix-build-ucx-1.11.2.drv-0/bguibertd/spack-stage-ucx-1.11.2-p4f833gchjkggkd1jhjn4rh93wwk2xn5/spack-src/src/ucs/datastruct/linear_func.h:147:21: error: comparison with infinity always evaluates to false in fast floating point mode> if (isnan(x) || isinf(x))
        #ucx.depends.compiler = packs.default.pack.pkgs.compiler;
      };

      pkgs = pack: [
        {
          pkg = pack.pkgs.compiler;
          projection = "intel/{version}";
        }
      ];
    })
