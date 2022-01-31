{
  description = "A flake for building packages on /software-like structure";

  inputs = {
    #nixpkgs.url          = "github:dguibert/nixpkgs/pu-nixpack";
    nixpkgs.url          = "github:dguibert/nixpkgs?rev=fa4a95770278b56ca493bafc4496207b9b01eee5";

    #nix.url              = "github:dguibert/nix/a828ef7ec896e4318d62d2bb5fd391e1aabf242e";
    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    nur_dguibert.url     = "github:dguibert/nur-packages/master";
    nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
    nur_dguibert.inputs.nix.follows = "nix";
    nur_dguibert.inputs.flake-utils.follows = "flake-utils";

    #nixpack.url = "github:dguibert/nixpack/pu";
    #nixpack.url = "git+ssh://genji/home_nfs/bguibertd/software-cepp-spack/nixpack?ref=pu";
    nixpack.url = "git+file:///home_nfs/bguibertd/software-cepp-spack/nixpack?ref=pu";
    nixpack.inputs.spack.follows = "spack";
    nixpack.inputs.nixpkgs.follows = "nixpkgs";

    #spack = { url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    #spack = { url = "git+https://gitlab.bench.local:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?ref=develop"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?rev=635b4b4ffedb7c635c63975802955f6ace8b8b7d"; flake=false; };
  };

  outputs = { self, nixpkgs, ... }@inputs: let
    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = system:
      import nixpkgs {
        localSystem = {
          inherit system;
          # gcc = { arch = "x86-64" /*target*/; };
        };
        overlays =  [
          inputs.nix.overlay
          (import "${inputs.nur_dguibert}/hosts/genji/overlay.nix")
          (import "${inputs.nixpack}/nixpkgs/overlay.nix")
          self.overlay
        ];
        config = {
          replaceStdenv = import "${inputs.nixpack}/nixpkgs/stdenv.nix";
          allowUnfree = true;
        };
      };

    isLDep = builtins.elem "link";
    isRDep = builtins.elem "run";
    isRLDep = d: isLDep d || isRDep d;

    rpmVersion = pkg: inputs.nixpack.lib.capture ["/bin/rpm" "-q" "--queryformat=%{VERSION}" pkg];
    rpmExtern = pkg: { extern = "/usr"; version = rpmVersion pkg; };

    corePacks = system: let
      pkgs = nixpkgsFor system;
      bootstrap = bootstrapPacks self;
      self = inputs.nixpack.lib.packs {
        inherit system;
        os = "rhel8";
        label="core";
        global.verbose = true;
        global.fixedDeps = true;
        /* any runtime dependencies use the current packs, others fall back to core */
        global.resolver = deptype:
          if isRLDep deptype
          then null else self;
        spackConfig.config.source_cache="/software/spack/mirror";
        spackConfig.config.url_fetch_method = "curl";

        spackPython = "${pkgs.python3}/bin/python3";
        #spackPython = if system == "x86_64-linux"  then "/home_nfs/bguibertd/.home-x86_64/.nix-profile/bin/python3"
        #         else if system == "aarch64-linux" then "/home_nfs/bguibertd/.home-aarch64/.nix-profile/bin/python3"
        #         else throw "python not already installed for system: ${system}";
        spackEnv.PATH = "/bin:/usr/bin:/usr/sbin";
        spackEnv.PROXYCHAINS_CONF_FILE="/dev/shm/proxychains.conf";
        spackEnv.LD_PRELOAD="/dev/shm/libproxychains4.so";
        ## only fixedCA drvs allow impureEnvVars
        #spackEnv.impureEnvVars = [
        #  "http_proxy" "https_proxy"
        #  "PROXYCHAINS_CONF_FILE" "LD_PRELOAD"
        #];
        repos = [
          ./repo
        ];
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
        };

        package = {
          compiler = bootstrap.pkgs.gcc.withPrefs { version="11"; };
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
          autoconf  = rpmExtern "autoconf";
          automake  = rpmExtern "automake";
          bzip2     = rpmExtern "bzip2";
          diffutils = rpmExtern "diffutils";
          libtool   = rpmExtern "libtool";
          m4        = rpmExtern "m4";
          openssh   = rpmExtern "openssh";
          openssl   = rpmExtern "openssl";
          pkgconfig = rpmExtern "pkgconf";
          #perl      = rpmExtern "perl"; # https://github.com/spack/spack/issues/19144
          gdbm.version= "1.19";
          slurm     = rpmExtern "slurm" // {
            variants = {
              #pmix = true;
              hwloc = true;
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
        };
      };
    in self;

    modulesConfig = {
      config = {
        hierarchy = ["mpi"];
        hash_length = 0;
        prefix_inspections = {
          "lib" = ["LIBRARY_PATH"];
          "lib64" = ["LIBRARY_PATH"];
          "lib/intel64" = ["LIBRARY_PATH"]; # for intel
          "include" = ["C_INCLUDE_PATH" "CPLUS_INCLUDE_PATH"];
          "" = ["{name}_ROOT"];
        };
        all = {
          autoload = "none";
          prerequisites = "direct";
          suffixes = {
            "^mpi" = "mpi";
            "^cuda" = "cuda";
          };
          filter = {
            environment_blacklist = ["CC" "FC" "CXX" "F77"];
          };
        };
        openmpi = {
          environment = {
            set = {
              OPENMPI_VERSION = "{version}";
            };
          };
        };
      };
    };

    bootstrapPacks = core: core.withPrefs {
      label = "bootstrap";
      global = {
        resolver = null;
        tests = false;
      };
      package = {
        /* must be set to an external compiler capable of building compiler (above) */
        compiler = {
          name = "gcc";
        } // rpmExtern "gcc";

        ncurses = rpmExtern "ncurses" // {
          variants = {
            termlib = false;
            abi = "5";
          };
        };
      };
    };


    NIX_CONF_DIR_fun = pkgs: let
      nixConf = pkgs.writeTextDir "opt/nix.conf" ''
        max-jobs = 8
        cores = 0
        sandbox = false
        auto-optimise-store = true
        require-sigs = true
        trusted-users = nixBuild dguibert
        allowed-users = *

        system-features = recursive-nix nixos-test benchmark big-parallel kvm
        sandbox-fallback = false
        use-sqlite-wal = false

        keep-outputs = true       # Nice for developers
        keep-derivations = true   # Idem
        extra-sandbox-paths = /opt/intel/licenses=/home/dguibert/nur-packages/secrets?
        experimental-features = nix-command flakes recursive-nix
        system-features = recursive-nix nixos-test benchmark big-parallel gccarch-x86-64
        #extra-platforms = i686-linux aarch64-linux

        builders = @/tmp/nix--home_nfs-bguibertd-machines
      '';
    in
      "${nixConf}/opt";

  in (inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
    let pkgs = nixpkgsFor system;
    in rec {

      legacyPackages = let
        packs = corePacks system;
      in pkgs // packs // {
        mods = packs.modules (inputs.nixpack.lib.recursiveUpdate modulesConfig ({
          pkgs = [
            packs.pkgs.openmpi
            packs.pkgs.osu-micro-benchmarks
          ];
        }));
      };

      devShell = with pkgs; mkShell rec {
        name  = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
        ENVRC = name;
        nativeBuildInputs = [ pkgs.nix jq
                            ];
        shellHook = ''
          export ENVRC=${name}
          export XDG_CACHE_HOME=$HOME/.cache/${name}
          export NIX_STORE=${nixStore}/store
          unset TMP TMPDIR TEMPDIR TEMP
          unset NIX_PATH
        '';
        NIX_CONF_DIR = NIX_CONF_DIR_fun pkgs;
      };

    })) // {
      overlay = final: prev: let
        system = prev.system;
        core_packs = corePacks system;
      in {
        corePacks = core_packs;

        nix = prev.nix.overrideAttrs (o: {
          patches = [
            "${inputs.nur_dguibert}/pkgs/nix-unshare.patch"
            #"${inputs.nur_dguibert}/pkgs/nix-sqlite-unix-dotfiles-for-nfs.patch"
          ];
        });

        viridianSImg = prev.singularity-tools.buildImage {
          name = "viridian";
          diskSize = 4096;
          contents = with final.corePacks; [
            pkgs.py-viridian-workflow
          ];
        };
        viridianDocker = prev.dockerTools.buildImage {
          name = "viridian";
          contents = with final.corePacks; [
            pkgs.py-viridian-workflow
          ];
        };

        libffi = prev.libffi.overrideAttrs (o: {
          doCheck = false; # whoami error with nss_ssd
        });
        go_bootstrap = prev.go_bootstrap.overrideAttrs (attrs: {
          doCheck = false;
        });
        go_1_16 = prev.go_1_16.overrideAttrs (attrs: {
          doCheck = false;
        });

      };
  };

}
