final:
# default benchmarking env for ai4sim
pack:
pack._merge (self:
    with self; {
      label = "ai4sim_" + pack.label;

      # py-numba dependency py-numpy: package py-numpy@1.23.3+blas+lapack does not match dependency constraints {"version":"1.18:1.22"}
      package.py-matplotlib.version = "3.7";
      package.py-numpy.version = "1.24.3";
      # llvm: has conflicts: %gcc@:10
      package.llvm.variants.libcxx = "runtime";
      package.llvm.variants.flang = false;
      package.llvm.version = "14";
      # py-llvmlite dependency llvm: package llvm@15.0.0+clang+compiler-rt~cuda+flang+gold+internal_unwind~ipo~libcxx~link_llvm_dylib+lld+lldb+llvm_dylib+mlir+omp_as_runtime~omp_debug~omp_tsan+polly~python~split_dwarf~z3 code_signing= cuda_arch= targets=~aarch64,~all,~amdgpu,~arm,~avr,~bpf,~cppbackend,~hexagon,~lanai,~mips,~msp430,+none,~nvptx,~powerpc,~riscv,~sparc,~systemz,~webassembly,~x86,~xcore build_type=Release shlib_symbol_version=none version_suffix=none does not match dependency constraints {"variants":{"flang":false},"version":"11.0:11"}
      # py-oauthlib dependency py-cryptography: package py-cryptography@36.0.1 idna= does not match dependency constraints {"version":"3.0.0:3"}
      package.py-cryptography.version = "3";
      # py-setuptools-rust dependency py-setuptools: package py-setuptools@57.4.0 does not match dependency constraints {"version":"62.4:"}
      # py-numpy dependency py-setuptools: package py-setuptools@62.4.0 does not match dependency constraints {"version":":59"}
      package.py-setuptools-rust.version = "1.2";
      # rust dependency libgit2: package libgit2@1.4.3~curl~ipo+mmap+ssh build_type=RelWithDebInfo https=system does not match dependency constraints {"version":":1.3"}
      package.libgit2.version = "1.3";
      package.swig.version = "4.0";

      package.py-gast.version = "0.4.0";
      package.py-beniget.depends.py-gast = self.pack.pkgs.py-gast.withPrefs {version = "0.5.0";};
      package.py-numpy.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pyyaml.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pythran.version = "0.12";
      package.py-pythran.depends.py-gast = self.pack.pkgs.py-gast.withPrefs {version = "0.5.0";};
      package.py-scipy.depends.py-pythran = self.pack.pkgs.py-pythran;
      package.py-pandas.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-grpcio.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-pybind11.version = "2.11.0";
      package.py-cython.version = "0.29";
      package.py-setuptools.version = "62";
      package.py-urllib3.version = "1";
      package.py-scipy.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-scipy.depends.py-pip = self.pack.pkgs.py-pip.withPrefs {version = "23.1";};
      package.meson.version = "1.2.1";

      package.py-tensorflow.variants.cuda = false;
      package.py-tensorflow.variants.nccl = false;
      #package.py-tensorflow.variants.cuda_arch.none = false;
      #package.py-tensorflow.variants.cuda_arch."80" = true;
      package.bazel.version = "5.1.1";
      package.py-tensorflow.depends.bazel = final.packs.default.pack.pkgs.bazel.withPrefs {version = self.package.bazel.version;};
      package.py-keras.depends.bazel = final.packs.default.pack.pkgs.bazel.withPrefs {version = self.package.bazel.version;};
      package.py-protobuf.depends.bazel = final.packs.default.pack.pkgs.py-protobuf.withPrefs {version = self.package.py-protobuf.version;};
      package.py-tensorflow.depends.hdf5 = self.pack.pkgs.hdf5;
      package.hdf5.variants.mpi = false;
      package.py-h5py.variants.mpi = false;
      package.py-h5py.depends.py-cython = self.pack.pkgs.py-cython;
      package.py-h5py.depends.py-setuptools = self.pack.pkgs.py-setuptools;
      package.re2.variants.shared = true;
      package.py-libclang.depends.llvm = self.pack.pkgs.llvm;
      #package.py-libclang.depends.llvm = final.packs.default.pack.pkgs.llvm.withPrefs { version = self.package.llvm.version; };
      package.py-typing-extensions.version = "4.5";

      package.py-keras.version = "2.12";
      package.py-tensorboard.version = "2.12";
      package.py-tensorflow.version = "2.12";
      #package.py-tensorflow.depends.py-protobuf = self.pack.pkgs.py-protobuf.withPrefs { variants.cpp = true; };
      package.py-protobuf.variants.cpp = true;
      package.py-protobuf.version = "3.20.3";
      package.protobuf.version = "3.20.3";
      package.py-pip.version = "23.0";
      package.py-google-auth-oauthlib.version = "0.4";
      package.py-tensorboard-data-server.version = "0.6";
      package.python.version = "3.10";

      package.py-torch.variants.cuda = false;
      package.sleef.version = "3.5.1_2020-12-22";
      package.boost.variants.atomic = true;
      package.boost.variants.chrono = true;
      package.boost.variants.exception = true;
      package.boost.variants.system = true;
      package.boost.variants.thread = true;
      package.intel-oneapi-mkl.version = "2023.2.0";
      package.py-onnxruntime.version = "1.16.3";

      mod_pkgs = with self.pack.pkgs; [
        compiler
        python
        py-mlflow
        py-pandas
        py-tensorflow #@2.9.3 +cuda cuda_arch=80
        py-tensorflow-estimator #@2.9.0
        py-keras #@2.9.0
        py-cffi

        py-torch

        py-onnxruntime

        # add raps/ifs
      ];
    })
