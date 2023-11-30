final:
# default benchmarking env for ai4sim
pack:
pack._merge (self:
    with self; {
      label = "ai4sim_torchfort_" + pack.label;

      package.py-numpy.version = "1.24";
      package.llvm.variants.flang = false;
      package.llvm.version = "14";
      ## py-llvmlite dependency llvm: package llvm@15.0.0+clang+compiler-rt~cuda+flang+gold+internal_unwind~ipo~libcxx~link_llvm_dylib+lld+lldb+llvm_dylib+mlir+omp_as_runtime~omp_debug~omp_tsan+polly~python~split_dwarf~z3 code_signing= cuda_arch= targets=~aarch64,~all,~amdgpu,~arm,~avr,~bpf,~cppbackend,~hexagon,~lanai,~mips,~msp430,+none,~nvptx,~powerpc,~riscv,~sparc,~systemz,~webassembly,~x86,~xcore build_type=Release shlib_symbol_version=none version_suffix=none does not match dependency constraints {"variants":{"flang":false},"version":"11.0:11"}
      package.swig.version = "4.0";

      package.py-numpy.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pyyaml.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pythran.version = "0.12";
      package.py-pythran.depends.py-gast = self.pack.pkgs.py-gast.withPrefs {version = "0.5.0";};
      package.py-scipy.depends.py-pythran = self.pack.pkgs.py-pythran;
      package.py-pandas.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-grpcio.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pybind11.version = "2.10.4";
      package.py-cython.version = "0.29";
      package.py-setuptools.version = "57";
      package.py-scipy.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-scipy.depends.py-pybind11 = self.pack.pkgs.py-pybind11;
      package.py-scipy.depends.py-meson-python = self.pack.pkgs.py-meson-python;
      package.py-cppy.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "68.0.0";};
      package.py-kiwisolver.depends.py-setuptools = self.pack.pkgs.py-setuptools.withPrefs {version = "68.0.0";};
      package.py-matplotlib.version = "3.7";
      package.meson.version = "1.2.1";
      package.py-wheel.version = "0.37.1";
      package.sleef.version = "3.5.1_2020-12-22";

      package.py-scipy.version = "1.11.0";
      package.py-scipy.depends.py-pip = self.pack.pkgs.py-pip.withPrefs {version = "23.1";};
      #package.py-meson-python.version = "0.12.0";
      package.py-protobuf.version = "3.17";
      package.protobuf.version = "3.17";
      package.py-pip.version = "23.0";

      package.torchfort.version = "master";
      package.torchfort.variants.examples-fortran = false; # need hdf5.mod from hdf5%nvhpc
      package.openmpi.version = "3"; # for cxx
      package.openmpi.variants.internal-pmix = true;
      package.hwloc.version = "1";
      package.openmpi.variants.cxx = true;
      # {"variants":{"atomic":true,"chrono":true,"exception":true,"system":true,"thread":true}}
      package.boost.variants.atomic = true;
      package.boost.variants.chrono = true;
      package.boost.variants.exception = true;
      package.boost.variants.system = true;
      package.boost.variants.thread = true;

      package.py-torch.variants.cuda = true;
      package.yaml-cpp.variants.shared = false;
      package.py-torch.variants.cuda_arch.none = false;
      package.py-torch.variants.cuda_arch."80" = true;
      package.py-torch.depends.py-pybind11 = self.pack.pkgs.py-pybind11;
      package.magma.variants.cuda = true;
      package.magma.variants.cuda_arch.none = false;
      package.magma.variants.cuda_arch."80" = true;
      package.nccl.variants.cuda = true;
      package.nccl.variants.cuda_arch.none = false;
      package.nccl.variants.cuda_arch."80" = true;

      package.gloo.variants.cuda = true;
      package.gloo.variants.cuda_arch.none = false;
      package.gloo.variants.cuda_arch."80" = true;

      repoPatch = {
        py-torch = spec: old:
          with self.pack.lib; {
            depends =
              old.depends
              // {
                py-pybind11 = [
                  (when (versionMatches spec.version "2:") {
                    deptype = ["build" "link" "run"];
                    version = "2.10.1:"; # FIX allow version greater than 2.10.1
                  })
                ];
              };
          };
      };

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi

        torchfort
      ];
    })
