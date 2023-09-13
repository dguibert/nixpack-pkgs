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
      package.roctracer-dev.version = package.hip.version or null;
      package.roctracer-dev.variants.rocm = true;
      package.roctracer-dev.variants.amdgpu_target.none = false;
      package.roctracer-dev.variants.amdgpu_target."gfx90a" = true;
      package.rocprofiler-dev.version = package.hip.version or null;
      package.hsa-rocr-dev.version = package.hip.version or null;
      # hip dependency hsa-rocr-dev: package hsa-rocr-dev@5.4.3+image~ipo+shared build_system=cmake build_type=Release generator=make does not match dependency constraints {"version":"5.5.1"}
      package.comgr.version = package.hip.version or null;
      package.llvm-amdgpu.version = package.hip.version or null;
      package.hipify-clang.version = package.hip.version or null;
      package.hsakmt-roct.version = package.hip.version or null;
      package.rocminfo.version = package.hip.version or null;
      package.rocm-core.version = package.hip.version or null;
      package.roctracer-dev-api.version = package.hip.version or null;

      #package.py-pyyaml.depends.py-cython = self.pack.pkgs.py-cython;
      #package.py-cython.version = "0.29.34";
      #package.rocprofiler-dev.depends.py-pyyaml = self.pack.pkgs.py-pyyaml;
      package.hippify-clang.patches = [];

      package.mesa.variants.llvm = false;

      repoPatch = {
        #rocprofiler-dev = spec: old: {
        #  depends = old.depends // {
        #    py-lxml.deptype = ["build" ];
        #    py-pyyaml.deptype = ["build" ];
        #    py-barectf.deptype = ["build" ];
        #    py-cppheaderparser.deptype = [ "build" ];
        #    hip.deptype = [ "build" "link" ];
        #    googletest.deptype = [ "build" "test" ];
        #  };
        #  patches = [ ../patches/0001-Continue-build-in-absence-of-aql-profile-lib.patch ];
        #  build.setup = ''
        #    cmakeargs = pkg.cmake_args()
        #    cmakeargs.append("-DHIP_ROOT_DIR={0}".format(spec["hip"].prefix))
        #    pkg.cmake_args = lambda: cmakeargs
        #  '';
        #};
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
        hip
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
