{
  default_pack,
  hpcw_repo,
  packsFun,
  isRLDep,
  packs,
}:
default_pack._merge (self:
    with self; {
      label = "core";
      global = {
        resolver = deptype:
          if isRLDep deptype
          then null
          else packs.default.pack;
      };
      repos = [
        ../repo
        hpcw_repo
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
      };

      package = {
        openmpi = {
          version = "4.1.3";
          variants = {
            fabrics = {
              none = false;
              ofi = true;
              ucx = true;
              psm = false;
              psm2 = false;
              verbs = true;
              #mofed = true;
            };
            schedulers = {
              none = false;
              slurm = true;
            };
            pmi = false;
            pmix = true;
            #pmix = false; # patched to mean internal
            static = false;
            legacylaunchers = true;
          };
        };
        gcc.version = "10";
        pmix.version = "4.1.1";
        boost.version = "1.72.0";
        binutils = {
          variants = {
            gold = true;
            ld = true;
          };
        };
        hdf5 = {
          variants = {
            hl = true;
            fortran = true;
            szip = true;
          };
          depends.szip = packs.default.pack.pkgs.szip;
        };
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
        ucx = {
          variants = {
            thread_multiple = true;
            cma = true;
            rc = true;
            dc = true;
            ud = true;
            mlx5-dv = true;
            ib-hw-tm = true;
            knem = false;
            rocm = true;
          };
        };

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
        py-setuptools.version = "57.4.0"; # for py-scpiy

        # no need to be recompiled for each compiler
        patchelf.depends.compiler = packs.default.pack.pkgs.compiler;
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
        python.depends.compiler = packs.default.pack.pkgs.compiler;
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
        readline.depends.compiler = packs.default.pack.pkgs.compiler;
        texinfo.depends.compiler = packs.default.pack.pkgs.compiler;
        xz.depends.compiler = packs.default.pack.pkgs.compiler;
        zlib.depends.compiler = packs.default.pack.pkgs.compiler;

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
      };
    })
