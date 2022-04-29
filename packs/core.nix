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
    global.verbose = true;
    global.fixedDeps = true;
    /* any runtime dependencies use the current packs, others fall back to core */
    global.resolver = deptype: if isRLDep deptype then null else self;

    spackConfig.config = {
      url_fetch_method = "curl";
    }
    // (extraConf.spackConfig.config or {});

    repos = [
      ./repo
    ]
    ++ (extraConf.repos or [])
    ;
    repoPatch = let
      nocompiler = spec: old: { depends = old.depends or {} // { compiler = null; }; };
    in {
      arm-forge = nocompiler;
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
          pmi = true;
          pmix = false;
          static = false;
          thread_multiple = true;
          legacylaunchers = true;
        };
      };
      boost.version = "1.72.0";
      binutils = {
        variants = {
          gold = true;
          ld = true;
        };
      };
      hdf5.variants = { hl = true; };
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
      hwloc.depends.compiler = bootstrapPacks.pkgs.compiler;
      libnl.depends.compiler = bootstrapPacks.pkgs.compiler;
      libevent.depends.compiler = bootstrapPacks.pkgs.compiler;
      libpciaccess.depends.compiler = bootstrapPacks.pkgs.compiler;
      numactl.depends.compiler = bootstrapPacks.pkgs.compiler;
      # for aocc, infinite recursion breaking
      berkeley-db.depends.compiler = bootstrapPacks.pkgs.compiler;
      freetype.depends.compiler = bootstrapPacks.pkgs.compiler;
      gdbm.depends.compiler = bootstrapPacks.pkgs.compiler;
      gdbm.version = "1.19"; # for perl
      libiconv.depends.compiler = bootstrapPacks.pkgs.compiler;
      libtool.depends.compiler = bootstrapPacks.pkgs.compiler;
      libxml2.depends.compiler = bootstrapPacks.pkgs.compiler;
      ncurses.depends.compiler = bootstrapPacks.pkgs.compiler;
      perl.depends.compiler = bootstrapPacks.pkgs.compiler;
      rdma-core.depends.compiler = bootstrapPacks.pkgs.compiler;
      readline.depends.compiler = bootstrapPacks.pkgs.compiler;
      texinfo.depends.compiler = bootstrapPacks.pkgs.compiler;
      xz.depends.compiler = bootstrapPacks.pkgs.compiler;
      zlib.depends.compiler = bootstrapPacks.pkgs.compiler;

      # knem: has conflicts: %aocc Linux kernel module must be compiled with gcc
      knem.depends.compiler = bootstrapPacks.pkgs.compiler;

      blom = {
        variants = {
          processors = 512;
          grid = "channel";
          mpi = true;
          parallel_netcdf = true;
        };
      };
    }
    // (extraConf.package or {})
    ;
  });
in self
