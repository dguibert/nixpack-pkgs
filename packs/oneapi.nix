{packs}:
packs.default._merge (self:
    with self; {
      label = "intel-oneapi";
      repoPatch = {
        intel-oneapi-compilers = spec: old: {
          compiler_spec = "oneapi";
          paths = {
            cc = "compiler/latest/linux/bin/icx";
            cxx = "compiler/latest/linux/bin/icpx";
            f77 = "compiler/latest/linux/bin/ifx";
            fc = "compiler/latest/linux/bin/ifx";
          };
          provides =
            old.provides
            or {}
            // {
              compiler = ":";
            };
          depends =
            old.depends
            or {}
            // {
              compiler = null;
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
        # /dev/shm/nix-build-ucx-1.11.2.drv-0/bguibertd/spack-stage-ucx-1.11.2-p4f833gchjkggkd1jhjn4rh93wwk2xn5/spack-src/src/ucs/datastruct/linear_func.h:147:21: error: comparison with infinity always evaluates to false in fast floating point mode> if (isnan(x) || isinf(x))
        ucx.depends.compiler = packs.default.pack.pkgs.compiler;
      };

      pkgs = pack: [
        {
          pkg = pack.pkgs.compiler;
          projection = "oneapi/{version}";
          # TODO fix PATH to include legacy compiliers
        }
      ];
    })
