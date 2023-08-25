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

      # rocprofiler-dev dependency hsa-rocr-dev: package hsa-rocr-dev@5.5.1+image~ipo+shared build_system=cmake build_type=Release generator=make does not match dependency constraints {"version":"5.4.3"}
      package.roctracer-dev.version = "5.4";
      package.roctracer-dev.variants.rocm = true;
      package.roctracer-dev.variants.amdgpu_target.none = false;
      package.roctracer-dev.variants.amdgpu_target."gfx90a" = true;
      package.rocprofiler-dev.version = "5.4";
      package.hsa-rocr-dev.version = "5.4";
      # hip dependency hsa-rocr-dev: package hsa-rocr-dev@5.4.3+image~ipo+shared build_system=cmake build_type=Release generator=make does not match dependency constraints {"version":"5.5.1"}
      package.hip.version = "5.4";
      package.comgr.version = "5.4";
      package.llvm-amdgpu.version = "5.4";
      package.hipify-clang.version = "5.4";
      package.hsakmt-roct.version = "5.4";
      package.rocminfo.version = "5.4";
      package.roctracer-dev-api.version = "5.4";

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
