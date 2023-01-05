final:
# default benchmarking env for ai4sim
pack:
pack._merge (self:
    with self; {
      label = "ai4sim_" + pack.label;

      # py-numba dependency py-numpy: package py-numpy@1.23.3+blas+lapack does not match dependency constraints {"version":"1.18:1.22"}
      package.py-numpy.version = "1.22";
      # py-scipy dependency py-pythran: package py-pythran@0.9.12 does not match dependency constraints {"version":"0.10:"}
      package.py-pythran.version = "0.10";
      # llvm: has conflicts: %gcc@:10
      package.llvm.variants.libcxx = false;
      package.llvm.variants.flang = false;
      package.llvm.version = "11";
      # py-llvmlite dependency llvm: package llvm@15.0.0+clang+compiler-rt~cuda+flang+gold+internal_unwind~ipo~libcxx~link_llvm_dylib+lld+lldb+llvm_dylib+mlir+omp_as_runtime~omp_debug~omp_tsan+polly~python~split_dwarf~z3 code_signing= cuda_arch= targets=~aarch64,~all,~amdgpu,~arm,~avr,~bpf,~cppbackend,~hexagon,~lanai,~mips,~msp430,+none,~nvptx,~powerpc,~riscv,~sparc,~systemz,~webassembly,~x86,~xcore build_type=Release shlib_symbol_version=none version_suffix=none does not match dependency constraints {"variants":{"flang":false},"version":"11.0:11"}
      # py-oauthlib dependency py-cryptography: package py-cryptography@36.0.1 idna= does not match dependency constraints {"version":"3.0.0:3"}
      package.py-cryptography.version = "3";
      # py-setuptools-rust dependency py-setuptools: package py-setuptools@57.4.0 does not match dependency constraints {"version":"62.4:"}
      # py-numpy dependency py-setuptools: package py-setuptools@62.4.0 does not match dependency constraints {"version":":59"}
      package.py-setuptools-rust.version = "1.2";
      # rust dependency libgit2: package libgit2@1.4.3~curl~ipo+mmap+ssh build_type=RelWithDebInfo https=system does not match dependency constraints {"version":":1.3"}
      package.libgit2.version = "1.3";

      repoPatch = {
        llvm = spec: old: {
          provides =
            old.provides
            or {}
            // {
              compiler = null;
            };
        };
      };

      mod_pkgs = with self.pack.pkgs; [
        py-mlflow
        { pkg=llvm;
          projection="llvm/{version}";
        }
        { pkg=bzip2;
          projection="bzip2/{version}";
        }
        { pkg=openssl;
          projection="opensll/{version}";
        }
        { pkg=py-setuptools;
          projection="py-setuptools/{version}";
        }
      ];
    })
