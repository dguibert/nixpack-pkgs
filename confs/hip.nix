final:
# default benchmarking env with jube
pack:
pack._merge (self:
    with self; {
      label = "hip_" + pack.label;

      package.llvm.version = "12";
      package.libllvm = {name = "llvm-amdgpu";};
      package.ucx.variants = {
        cuda = true;
        gdrcopy = false;
        rocm = true; # +rocm gdrcopy > 2.0 does not support rocm
      };

      repoPatch = {
        llvm-amdgpu = spec: old: {
          provides =
            old.provides
            or {}
            // {
              compiler = null;
            };
        };
      };

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        hip
        {
          pkg = llvm-amdgpu;
          context.provides = []; # not real compiler
        }
        gettext
        rocprofiler-dev
        roctracer-dev
        cmake
      ];
    })
