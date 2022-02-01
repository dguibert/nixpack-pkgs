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
        version = "4.1";
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
      gdbm.version= "1.19";
      ucx = {
        variants = {
          thread_multiple = true;
          cma = true;
          rc = true;
          dc = true;
          ud = true;
          mlx5-dv = true;
          ib-hw-tm = true;
          knem = true;
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
    }
    // (extraConf.package or {})
    ;
  });
in self
