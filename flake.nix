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
    nixpack.url = "git+ssh://genji/home_nfs/bguibertd/software-cepp-spack/nixpack?ref=pu";
    #nixpack.url = "git+file:///home_nfs/bguibertd/software-cepp-spack/nixpack?ref=pu";
    nixpack.inputs.spack.follows = "spack";
    nixpack.inputs.nixpkgs.follows = "nixpkgs";

    spack = { url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    #spack = { url = "git+https://gitlab.bench.local:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?ref=develop"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?rev=635b4b4ffedb7c635c63975802955f6ace8b8b7d"; flake=false; };
  };

  outputs = { self, nixpkgs, ... }@inputs: let

    #host = "genji";
    host = "nixos";
    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = system:
      import nixpkgs {
        localSystem = {
          inherit system;
          # gcc = { arch = "x86-64" /*target*/; };
        };
        overlays =  [
          inputs.nix.overlay
          (import "${inputs.nixpack}/nixpkgs/overlay.nix")
          self.overlay
        ]
        ++ nixpkgs.lib.optionals (host != "nixos") [
          (import "${inputs.nur_dguibert}/hosts/${host}/overlay.nix")
        ];
        config = {
          replaceStdenv = import "${inputs.nixpack}/nixpkgs/stdenv.nix";
          allowUnfree = true;
        };
      };

    isLDep = builtins.elem "link";
    isRDep = builtins.elem "run";
    isRLDep = d: isLDep d || isRDep d;

    rpmVersion = pkg: inputs.nixpack.lib.capture ["/bin/rpm" "-q" "--queryformat=%{VERSION}" pkg] {};
    rpmExtern = pkg: { extern = "/usr"; version = rpmVersion pkg; };

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
          autoload = "direct";
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

      legacyPackages = pkgs;

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
      lib.findModDeps = pkgs: with inputs.nixpack.lib; with builtins; let
          mods = map (x: if x ? spec
                         then { pkg=x; }
                         else x ) pkgs;
          pred = x: x.pkg != null && (isRLDep x.pkg.deptype);

          pkgOrSpec = p: p.pkg.spec or p.pkg or p;
          adddeps = s: pkgs: add s (filter (p: p != null && ! (any (x: pkgOrSpec x == pkgOrSpec p) s) && pred p)
            (nubBy (x: y: pkgOrSpec x == pkgOrSpec y)
                   (concatMap (p: map (x: { pkg=x; }) (attrValues p.pkg.spec.depends or {})) pkgs)));
            add = s: pkgs: if pkgs == [] then s else adddeps (s ++ pkgs) pkgs;
          in add [] (toList mods);


      overlay = final: prev: let
        system = prev.system;
        nocompiler = spec: old: { depends = old.depends or {} // { compiler = null; }; };

        overlaySelf = with overlaySelf; with prev; {
          inherit isLDep isRDep isRLDep;
          inherit rpmVersion rpmExtern;
          bootstrapPacks = import ./bootstrap-pack.nix {
              inherit corePacks rpmExtern;
              extraConf = import ./${host}-bootstrap.nix { inherit rpmExtern pkgs; };
          };

          corePacks = import ./core-pack.nix inputs.nixpack.lib.packs {
            inherit system bootstrapPacks pkgs isRLDep rpmExtern;
            extraConf = import ./${host}-core.nix { inherit rpmExtern pkgs inputs; };
          };

          intelPacks = intelOneApiPacks.withPrefs {
            label = "intel";
            repoPatch = {
              intel-oneapi-compilers = spec: old: {
                compiler_spec = "intel"; # can be overridden as "intel" with prefs
                provides = old.provides or {} // {
                  compiler = ":";
                };
                depends = old.depends or {} // {
                  compiler = null;
                };
              };
            };
          };
          intelOneApiPacks = corePacks.withPrefs {
            label = "intel-oneapi";
            repoPatch = {
              intel-oneapi-compilers = spec: old: {
                compiler_spec = "oneapi"; # can be overridden as "intel" with prefs
                provides = old.provides or {} // {
                  compiler = ":";
                };
                depends = old.depends or {} // {
                  compiler = null;
                };
              };
            };
            package = {
              compiler = { name = "intel-oneapi-compilers"; };
              # /dev/shm/nix-build-ucx-1.11.2.drv-0/bguibertd/spack-stage-ucx-1.11.2-p4f833gchjkggkd1jhjn4rh93wwk2xn5/spack-src/src/ucs/datastruct/linear_func.h:147:21: error: comparison with infinity always evaluates to false in fast floating point mode> if (isnan(x) || isinf(x)) {
              ucx = overlaySelf.corePacks.pkgs.ucx // {
                depends.compiler = overlaySelf.corePacks.pkgs.compiler;
              };
            };
          };

          aoccPacks = corePacks.withPrefs {
            package = {
              compiler = { name = "aocc"; };
              aocc.variants.license-agreed = true;
            };

            repoPatch = {
              aocc = spec: old: {
                paths = {
                  cc = "bin/clang";
                  cxx = "bin/clang++";
                  f77 = "bin/flang";
                  fc = "bin/flang";
                };
                provides = old.provides or {} // {
                  compiler = ":";
                };
                depends = old.depends // {
                  compiler = null;
                };
              };

            };
          };

          # pack = import ./pack {
          #   version
          #   corePacks
          #   bootstrapPacks }

          mkModules = pack: pkgs: pack.modules (inputs.nixpack.lib.recursiveUpdate modulesConfig ({
            coreCompilers = [ final.bootstrapPacks.pkgs.compiler ];
            pkgs = self.lib.findModDeps pkgs;
          }));

          mods_osu = final.mkModules final.corePacks ([]
            ++ (with final.corePacks.pkgs; [
                openmpi
                osu-micro-benchmarks
              ])
            ++ (with (final.corePacks.withPrefs {
              package.openmpi.version = "4.1.0";
              }).pkgs; [
                openmpi
                osu-micro-benchmarks
              ])
            ++ (with (intelPacks.withPrefs {
              }).pkgs; [
                { pkg=compiler;
                  projection="{name}-legacy/{version}";
                  # TODO fix PATH to include legacy compiliers
                }
                openmpi
                osu-micro-benchmarks
              ])
            ++ (with (intelOneApiPacks.withPrefs {
              }).pkgs; [
                openmpi
                osu-micro-benchmarks
              ])
	    #++ (with (aoccPacks.withPrefs {
            #  }).pkgs; [
            #    openmpi
            #    osu-micro-benchmarks
            #  ])
            );

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

      }; in overlaySelf;
  };

}
