{
  default_pack,
  hpcw_repo,
  cbm_repo,
  spack_configs_repo,
  spack_repo,
  packsFun,
  isRLDep,
  ifHasPy,
  packs,
}:
default_pack._merge (self:
    with self; {
      label = "core";
      global = {
        resolver = deptype:
          ifHasPy self.pack
          (
            if isRLDep deptype
            then self.pack
            else packs.default.pack
          );
      };
      repos = [
        ../repo
        hpcw_repo
        spack_configs_repo
        cbm_repo
        spack_repo
      ];
      repoPatch = let
        nocompiler = spec: old: {depends = old.depends or {} // {compiler = null;};};

        no_lua_recdep = spec: old: {
          depends =
            old.depends
            // {
              lua-luajit = null; # conflicts with lua
              lua-luajit-openresty = null;
            };
        };
      in {
        arm-forge = nocompiler;
        lua-luafilesystem = no_lua_recdep;
        lua-luaposix = no_lua_recdep;
        openmpi = spec: old: {
          build = {
            setup = ''
              configure_args = pkg.configure_args()
              if spec.satisfies("~pmix"):
                if '--without-mpix' in configure_args: configure_args.remove('--without-pmix')
              pkg.configure_args = lambda: configure_args
            '';
          };
        };
        intel-oneapi-compilers = spec: old: {
          build = {
            post = ''
              # remove installer cache/packagemanager and broken links to pythonpackages
              shutil.rmtree(f"{spec.prefix}/intel", ignore_errors=True)
            '';
          };
        };
      };

      package = {
        # openmpi@4.1.1+atomics~cuda+cxx~cxx_exceptions+gpfs~internal-hwloc~java~legacylaunchers+lustre~memchecker+pmi+pmix+romio~singularity~sqlite3~static+thread_multiple+vt~wrapper-rpath fabrics=cma,hcoll,knem,ucx schedulers=slurm
        openmpi = {
          variants = {
            fabrics = {
              none = false;
              cma = true;
              ofi = true;
              ucx = true;
              psm = false;
              psm2 = false;
              verbs = false; # https://github.com/open-mpi/ompi/issues/6517
            };
            schedulers = {
              none = false;
              slurm = true;
            };
            pmix = true;
            romio = true;
            vt = true;
            static = false;
            legacylaunchers = true;
          };
        };
        gcc.version = "10";
        gcc.variants.binutils = true;
        pmix.version = "4.1.1";
        boost.version = "1.72.0";
        # gcc dependency binutils: package binutils@2.38~gas+gold~headers~interwork+ld~libiberty~lto+nls+plugins libs=+shared,+static build_system=autotools does not match dependency constraints {"variants":{"gas":true,"ld":true,"libiberty":false,"plugins":true}}
        # llvm dependency binutils: package binutils@2.40+gas+gold~gprofng~headers~interwork+ld~libiberty~lto~nls~pgo+plugins libs=+shared,+static build_system=autotools compress_debug_sections=zlib does not match dependency constraints {"variants":{"gold":true,"headers":true,"ld":true,"plugins":true}}
        binutils = {
          variants = {
            gas = true;
            gold = true;
            ld = true;
            headers = true;
          };
        };
        szip = {name = "libszip";};
        hdf5 = {
          variants = {
            hl = true;
            fortran = true;
            szip = true;
            threadsafe = true;
          };
          depends.szip = packs.default.pack.pkgs.szip;
        };
        lua.version = "5.3"; # for llvm
        llvm.variants = {
          flang = true;
          mlir = true;
        };
        libiberty.variants.pic = true; # for dyninst
        libfabric = {
          variants = {
            fabrics = ["udp" "rxd" "shm" "sockets" "tcp" "rxm" "verbs" "mlx"];
          };
        };
        ucx.variants = {
          cma = true;
          dc = true;
          dm = true;
          logging = false;
          ib_hw_tm = true;
          knem = true;
          mlx5_dv = true;
          openmp = true;
          optimizations = true;
          parameter_checking = false;
          rc = true;
          rdmacm = true;
          thread_multiple = true;
          ud = true;
          verbs = true;
          xpmem = true;
        };

        # eccodes dependency openjpeg: package openjpeg@2.4.0~codec~ipo build_type=RelWithDebInfo does not match dependency constraints {"version":"1.5.0:1.5,2.1.0:2.3"}
        openjpeg.version = "2.3";
        openjpeg.depends.compiler = packs.default.pack.pkgs.compiler;

        minimap2.variants.js_engine.k8 = false;
        minimap2.variants.js_engine.node-js = true;
        py-viridian.version = "main";
        py-varifier.version = "master";

        cairo.variants = {
          X = false;
          fc = true;
          ft = true;
          gobject = true;
          pdf = true;
        };
        py-pybind11.version = "2.7.1"; # for py-scpiy
        py-pythran.version = "0.9.12"; # for py-scpiy
        #py-setuptools.version = "57.4.0"; # for py-scpiy

        # intel-oneapi-compilers dependency patchelf: package patchelf@0.18.0 build_system=autotools does not match dependency constraints {"version":":0.17"}
        patchelf.version = "0.17";

        # no need to be recompiled for each compiler
        unzip.depends.compiler = packs.default.pack.pkgs.compiler;
        swig.depends.compiler = packs.default.pack.pkgs.compiler;
        pcre2.depends.compiler = packs.default.pack.pkgs.compiler;
        binutils.depends.compiler = packs.default.pack.pkgs.compiler;
        libedit.depends.compiler = packs.default.pack.pkgs.compiler;
        patchelf.depends.compiler = packs.default.pack.pkgs.compiler;
        uuid.depends.compiler = packs.default.pack.pkgs.compiler;
        cmake.depends.compiler = packs.default.pack.pkgs.compiler;
        #eckit.depends.compiler = packs.default.pack.pkgs.compiler;
        #fckit.depends.compiler = packs.default.pack.pkgs.compiler;
        #fiat.depends.compiler = packs.default.pack.pkgs.compiler;
        gettext.depends.compiler = packs.default.pack.pkgs.compiler;
        hwloc.depends.compiler = packs.default.pack.pkgs.compiler;
        libevent.depends.compiler = packs.default.pack.pkgs.compiler;
        libnl.depends.compiler = packs.default.pack.pkgs.compiler;
        libpciaccess.depends.compiler = packs.default.pack.pkgs.compiler;
        lua.depends.compiler = packs.default.pack.pkgs.compiler;
        numactl.depends.compiler = packs.default.pack.pkgs.compiler;
        python = {
          resolver = deptype:
            if isRLDep deptype
            then self.pack
            else packs.default.pack;
          depends.compiler = packs.default.pack.pkgs.compiler;
        };
        # for aocc, infinite recursion breaking
        berkeley-db.depends.compiler = packs.default.pack.pkgs.compiler;
        freetype.depends.compiler = packs.default.pack.pkgs.compiler;
        gdbm.depends.compiler = packs.default.pack.pkgs.compiler;
        gdbm.version = "1.19"; # for perl
        libiconv.depends.compiler = packs.default.pack.pkgs.compiler;
        libtool.depends.compiler = packs.default.pack.pkgs.compiler;
        libxml2.depends.compiler = packs.default.pack.pkgs.compiler;
        ncurses.depends.compiler = packs.default.pack.pkgs.compiler;
        perl.depends.compiler = packs.default.pack.pkgs.compiler;
        rdma-core.depends.compiler = packs.default.pack.pkgs.compiler;
        rdma-core.depends.py-docutils = packs.default.pack.pkgs.py-docutils.withPrefs {depends.python = packs.default.pack.pkgs.python;};
        readline.depends.compiler = packs.default.pack.pkgs.compiler;
        texinfo.depends.compiler = packs.default.pack.pkgs.compiler;
        xz.depends.compiler = packs.default.pack.pkgs.compiler;
        zlib.depends.compiler = packs.default.pack.pkgs.compiler;
        zlib-ng.depends.compiler = packs.default.pack.pkgs.compiler;

        # knem: has conflicts: %aocc Linux kernel module must be compiled with gcc
        knem.depends.compiler = packs.default.pack.pkgs.compiler;

        blom = {
          variants = {
            processors = "512";
            grid = "channel";
            mpi = true;
            parallel_netcdf = true;
          };
        };

        #tar dependency zstd: package zstd@1.5.2~programs compression= libs=+shared,+static does not match dependency constraints {"variants":{"programs":true}}
        zstd.variants.programs = true;
        tar.depends.compiler = packs.default.pack.pkgs.compiler;
        pigz.depends.compiler = packs.default.pack.pkgs.compiler;
        zstd.depends.compiler = packs.default.pack.pkgs.compiler;
        libbsd.depends.compiler = packs.default.pack.pkgs.compiler;
        libxcrypt.depends.compiler = packs.default.pack.pkgs.compiler;
        libffi.depends.compiler = packs.default.pack.pkgs.compiler;
        libunwind.depends.compiler = packs.default.pack.pkgs.compiler;
        papi.depends.compiler = packs.default.pack.pkgs.compiler;
        elfutils.depends.compiler = packs.default.pack.pkgs.compiler;
        sqlite.depends.compiler = packs.default.pack.pkgs.compiler;
        libmd.depends.compiler = packs.default.pack.pkgs.compiler;
        expat.depends.compiler = packs.default.pack.pkgs.compiler;
        udunits.depends.compiler = packs.default.pack.pkgs.compiler;

        # timemory@=3.2.3%nvhpc@=23.5~allinea_map~caliper+compiler~cuda~cupti~dyninst+ert~examples+extra_optimizations~gotcha~gperftools+install_config+install_headers~ipo~kokkos_build_config~kokkos_tools~likwid~likwid_nvmon~lto~mpi~mpip_library~nccl~ompt~ompt_library~papi+pic~python~python_deps~python_hatchet~python_line_profiler+require_packages+shared~static+statistics~tau+tools+unity_build~upcxx~use_arch~vtune build_system=cmake build_type=Release cpu_target=auto cuda_arch=auto cudastd=14 cxxstd=14 generator=make tls_model=global-dynamic arch=linux-rhel8-x86_64_v3 /5pv8nsrcidqz52njkrqpbcg5nd3ah2vy
        timemory.depends.compiler = packs.default.pack.pkgs.compiler;
        timemory.variants = {
          caliper = true;
          gotcha = true;
          mpi = true;
          ompt = true;
          ompt_library = true;
          papi = true;
          python = true;
          python_hatchet = true;
          python_line_profiler = true;
        };
      };
    })
