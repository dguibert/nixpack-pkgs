{packs}:
packs.default._merge (self:
    with self; {
      label = "hip";

      package.llvm.version = "12";
      package.libllvm = {name = "llvm-amdgpu";};
      package.ucx.variants = {
        cuda = true;
        gdrcopy = false;
        rocm = true; # +rocm gdrcopy > 2.0 does not support rocm
      };

      # rocprofiler-dev dependency hsa-rocr-dev: package hsa-rocr-dev@5.5.1+image~ipo+shared build_system=cmake build_type=Release generator=make does not match dependency constraints {"version":"5.4.3"}
      package.roctracer-dev.version = package.hip.version or null;
      package.rccl.version = package.hip.version or null;
      package.rocprofiler-dev.version = package.hip.version or null;
      package.hsa-rocr-dev.version = package.hip.version or null;
      # hip dependency hsa-rocr-dev: package hsa-rocr-dev@5.4.3+image~ipo+shared build_system=cmake build_type=Release generator=make does not match dependency constraints {"version":"5.5.1"}
      package.comgr.version = package.hip.version or null;
      package.llvm-amdgpu.version = package.hip.version or null;
      package.hipify-clang.version = package.hip.version or null;
      package.hsakmt-roct.version = package.hip.version or null;
      package.rocminfo.version = package.hip.version or null;
      package.rocm-core.version = package.hip.version or null;
      package.rocm-cmake.version = package.hip.version or null;
      package.rocm-smi-lib.version = package.hip.version or null;
      package.roctracer-dev-api.version = package.hip.version or null;

      # hip dependency mesa: package mesa@23.0.3+glx+llvm+opengl~opengles+osmesa~strip swr= default_library=+shared,~static build_system=meson buildtype=release does not match dependency constraints {"variants":{"llvm":false}}
      package.mesa.variants.llvm = false;

      mod_pkgs = with self.pack.pkgs; [
        hip
        #rccl
        {
          pkg = llvm-amdgpu;
          context.provides = []; # not real compiler
        }
        gettext
        #rocprofiler-dev
        #roctracer-dev
        cmake
      ];
    })
