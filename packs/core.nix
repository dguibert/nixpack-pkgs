packs:
{ system
, bootstrapPacks
, pkgs
, isRLDep
, rpmExtern
, extraConf ? {}
}:
let
  self = packs (extraConf // {
    inherit system;
    label="core";
    global = {
      verbose = true;
      fixedDeps = true;
      /* any runtime dependencies use the current packs, others fall back to core */
      resolver = deptype: if isRLDep deptype then null else self;
    }
    // (extraConf.global or {});

    spackConfig.config = {
      url_fetch_method = "curl";
    }
    // (extraConf.spackConfig.config or {});

    repos = [
      ../repo
    ]
    ++ (extraConf.repos or [])
    ;
    repoPatch = let
      nocompiler = spec: old: { depends = old.depends or {} // { compiler = null; }; };

      no_lua_recdep = spec: old: {
        depends = old.depends // {
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
    }
    // (extraConf.repoPatch or {})
    ;

    package = {
      compiler = bootstrapPacks.pkgs.gcc.withPrefs { version="11"; };
      openmpi = {
        version = "4.1.2";
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
          fortran=true;
          szip = true;
        };
        depends.szip = self.pkgs.szip;
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

      minimap2.variants.js_engine.k8      = false;
      minimap2.variants.js_engine.node-js = true;
      py-viridian.version = "main";
      py-varifier.version = "master";

      cairo.variants = { X = false; fc = true; ft = true; gobject = true; pdf = true; };
      py-pybind11.version = "2.7.1"; # for py-scpiy
      py-pythran.version = "0.9.12"; # for py-scpiy
      py-setuptools.version = "57.4.0"; # for py-scpiy

      # no need to be recompiled for each compiler
      cmake.depends.compiler = self.pkgs.compiler;
      hwloc.depends.compiler = self.pkgs.compiler;
      libevent.depends.compiler = self.pkgs.compiler;
      libnl.depends.compiler = self.pkgs.compiler;
      libpciaccess.depends.compiler = self.pkgs.compiler;
      lua.depends.compiler = self.pkgs.compiler;
      python.depends.compiler = self.pkgs.compiler;
      numactl.depends.compiler = self.pkgs.compiler;
      # for aocc, infinite recursion breaking
      berkeley-db.depends.compiler = self.pkgs.compiler;
      freetype.depends.compiler = self.pkgs.compiler;
      gdbm.depends.compiler = self.pkgs.compiler;
      gdbm.version = "1.19"; # for perl
      libiconv.depends.compiler = self.pkgs.compiler;
      libtool.depends.compiler = self.pkgs.compiler;
      libxml2.depends.compiler = self.pkgs.compiler;
      ncurses.depends.compiler = self.pkgs.compiler;
      perl.depends.compiler = self.pkgs.compiler;
      rdma-core.depends.compiler = self.pkgs.compiler;
      readline.depends.compiler = self.pkgs.compiler;
      texinfo.depends.compiler = self.pkgs.compiler;
      xz.depends.compiler = self.pkgs.compiler;
      zlib.depends.compiler = self.pkgs.compiler;

      # knem: has conflicts: %aocc Linux kernel module must be compiled with gcc
      knem.depends.compiler = self.pkgs.compiler;

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
    }
    // (extraConf.package or {})
    ;
  });
in self
