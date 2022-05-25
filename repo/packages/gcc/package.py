from spack import *
import spack.pkg.builtin.gcc
import os

class Gcc(spack.pkg.builtin.gcc.Gcc):
    variant('profiled', default=False, description='Use Profile Guided Optimization')
#            when='+bootstrap %gcc')
# error: attribute 'compiler' missing
#
#       at /home_nfs/bguibertd/nix/store/2bw5ar5hs9yaqdhz76v792h2zc73iaj6-spack-repo.nix:46497:69:
#
#        46496|     build_type = ["RelWithDebInfo" "Debug" "Release" "MinSizeRel"];
#        46497|     profiled = when (variantMatches spec.variants.bootstrap true && spec.depends.compiler.spec.name == "gcc") false;
#             |                                                                     ^
#        46498|   };

