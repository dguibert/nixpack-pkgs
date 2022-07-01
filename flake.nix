{
  description = "A flake for building packages on /software-like structure";

  inputs.nixpkgs.url          = "github:dguibert/nixpkgs/pu-nixpack";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur_dguibert.inputs.nix.follows = "nix";
  inputs.nur_dguibert.inputs.flake-utils.follows = "flake-utils";

  inputs.nixpack.inputs.spack.follows = "spack";
  inputs.nixpack.inputs.nixpkgs.follows = "nixpkgs";
  inputs.spack.flake=false;

  outputs = { self
            , nixpkgs
            , nix
            , flake-utils
            , nur_dguibert
            , nixpack
            , spack
            , ... }@inputs: let

    host = "betzy";
    #host = "nixos";
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
          mods = map (x: addPkg x) pkgs;
          addPkg = x: if x ? spec
                      then if x.spec.extern == null then { pkg=x; }
                                                    else /*builtins.trace "addPkg: ${nixpkgs.lib.generators.toPretty { allowPrettyValues=true; } x.spec}"*/
                                                         { pkg=x; projection="${x.spec.name}/${x.spec.version}"; }
                      else x;
          pred = x: (isRLDep (x.pkg.deptype or []));

          pkgOrSpec = p: p.pkg.spec or p;
          adddeps = s: pkgs: add s
          (filter (p: /*builtins.trace "adddeps: ${nixpkgs.lib.generators.toPretty { allowPrettyValues = true; } p}"*/
                         p != null
                      && ! (any (x: pkgOrSpec x == pkgOrSpec p) s)
                      && pred p)
              (nubBy (x: y: pkgOrSpec x == pkgOrSpec y)
                     (concatMap (p: map (x: addPkg x)
                                        (attrValues (p.pkg.spec.depends or {}))
                                )
                  pkgs)
              )
            );
            add = s: pkgs: if pkgs == [] then s else adddeps (s ++ pkgs) pkgs;
          in add [] (toList mods);


      overlay = final: prev: let
        system = prev.system;
        nocompiler = spec: old: { depends = old.depends or {} // { compiler = null; }; };

        overlaySelf = with overlaySelf; with prev; {
          inherit isLDep isRDep isRLDep;
          inherit rpmVersion rpmExtern;
          bootstrapPacks = import ./packs/bootstrap.nix {
              inherit corePacks rpmExtern;
              extraConf = import ./hosts/${host}/bootstrap.nix { inherit rpmExtern pkgs; };
          };

          corePacks = import ./packs/core.nix inputs.nixpack.lib.packs {
            inherit system bootstrapPacks pkgs isRLDep rpmExtern;
            extraConf = import ./hosts/${host}/core.nix { inherit rpmExtern pkgs inputs; };
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
              # /dev/shm/nix-build-ucx-1.11.2.drv-0/bguibertd/spack-stage-ucx-1.11.2-p4f833gchjkggkd1jhjn4rh93wwk2xn5/spack-src/src/ucs/datastruct/linear_func.h:147:21: error: comparison with infinity always evaluates to false in fast floating point mode> if (isnan(x) || isinf(x))
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

          mkModules = pack: pkgs: pack.modules (inputs.nixpack.lib.recursiveUpdate modulesConfig ({
            coreCompilers = [ final.bootstrapPacks.pkgs.compiler ];
            pkgs = self.lib.findModDeps pkgs;
          }));

          mods_osu = final.mkModules final.corePacks ([
            ]
            ++ (with final.corePacks.pkgs; [
                mpi
                osu-micro-benchmarks
              ])
            ++ (with (final.corePacks.withPrefs {
              package.openmpi.version = "4.1.0";
              }).pkgs; [
                mpi
                osu-micro-benchmarks
              ])
            ++ (with (intelPacks.withPrefs {
              }).pkgs; [
                { pkg=compiler;
                  projection="intel/{version}";
                  context.unlocked_paths = [ "intel/{version}" ];
                  # TODO fix PATH to include legacy compiliers
                }
                mpi
                osu-micro-benchmarks
              ])
            ++ (with (intelOneApiPacks.withPrefs {
              }).pkgs; [
                { pkg=compiler;
                  projection="oneapi/{version}";

                  #environment = {
                  #  prepend_path.MODULEPATH = "{prefix}/linux-rhel8-x86_64/{name}/{version}";
                  #};
                }
                mpi
                osu-micro-benchmarks
              ])
            ++ (with (aoccPacks.withPrefs {
              }).pkgs; [
                mpi
                osu-micro-benchmarks
              ])
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

      };
      in overlaySelf
      # blom configurations
      // (inputs.nixpkgs.lib.listToAttrs (map (attr: with attr; inputs.nixpkgs.lib.nameValuePair (packs.name + variants.name + "Packs_" + grid + "_" + processors) (packs.pack grid processors variants.v))
        (inputs.nixpkgs.lib.cartesianProductOfSets {
          packs = [
            { name = "blomIntelOrig";
              pack = grid: processors: v: final.intelPacks.withPrefs {
                repoPatch = {
                  intel-parallel-studio = spec: old: {
                    compiler_spec = "intel@19.1.1.217";
                    provides = old.provides or {} // {
                      compiler = ":";
                    };
                    depends = old.depends or {} // {
                      compiler = null;
                    };
                  };
                };
                package.compiler = { name="intel-parallel-studio"; version="professional.2020.1"; };
                package.intel-parallel-studio.variants.mpi=false;
                package.mpi = { name="intel-mpi"; version="2019.7.217"; };
                package.blom = {
                  version = "local";
                  variants = let self = {
                    inherit grid processors;
                    mpi=true;
                    parallel_netcdf=true;
                    buildtype="release";
                  } // (v self); in self;
                };
              };
            }

            { name = "blomOneApi";
              pack = grid: processors: v: final.intelOneApiPacks.withPrefs {
                package.mpi = { name="intel-oneapi-mpi"; };
                package.blom = {
                  version = "local";
                  variants = let self = {
                    inherit grid processors;
                    mpi=true;
                    parallel_netcdf=true;
                    buildtype="release";
                  } // (v self); in self;
                };
              };
            }
            { name = "blomIntel";
              pack = grid: processors: v: final.intelPacks.withPrefs {
                package.mpi = { name="intel-oneapi-mpi"; };
                package.blom = {
                  version = "local";
                  variants = let self = {
                    inherit grid processors;
                    mpi=true;
                    parallel_netcdf=true;
                    buildtype="release";
                  } // (v self); in self;
                };
              };
            }
          ];
          grid = [
            "channel_small"
            "channel_medium"
            "channel_large"
          ];
          processors = [
            "1"
            "2"
            "4"
            "8"
            "16"
            "32"
            "64"
            "128"
            "256"
            "512"
            "1024"
          ];
          variants = [
            { name=""; v=variants: {}; }
            { name = "Opt0";
              v= variants: with variants; {
                optims.no = false;
                optims.opt0 = true;
                optims.opt1 = false;
                optims.opt2 = false;
              };
            }
            { name = "Opt1";
              v= variants: with variants; {
                optims.no = false;
                optims.opt1 = true;
                optims.opt2 = false;
              };
            }
            { name = "Opt2";
              v= variants: with variants; {
                optims.no = false;
                optims.opt1 = false;
                optims.opt2 = true;
              };
            }
            { name = "SafeOpts";
              v= variants: with variants; {
                optims.no = false;
                optims.opt0 = true;
                optims.opt1 = true;
                optims.opt2 = false;
              };
            }
            { name = "Opts";
              v= variants: with variants; {
                optims.no = false;
                optims.opt0 = true;
                optims.opt1 = true;
                optims.opt2 = true;
              };
            }
          ];
        })));
  };

}
