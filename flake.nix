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
  inputs.hpcw = { url = "git+file:///home_nfs/bguibertd/work/hpcw"; flake =false; };

  outputs = { self
            , nixpkgs
            , nix
            , flake-utils
            , nur_dguibert
            , nixpack
            , spack
            , hpcw
            , ... }@inputs: let

    host = "genji";
    #host = "nixos";
    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = system:
      import nixpkgs {
        localSystem = {
          inherit system;
          # gcc = { arch = "x86-64" /*target*/; };
        };
        overlays =  [
          inputs.nix.overlays.default
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
          "" = ["{name}_DIR"];
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
        intel = {
          environment = {
            set = {
              ONEAPI_ROOT = "{prefix}";
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

      devShells.default = with pkgs; mkShell rec {
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

      devShells.hpcwIntelEcrad = with pkgs; mkDevShell {
        name = "hpcw-intel-ecrad";
        mods = mkModules corePacks (with hpcwIntelPacks.pkgs; [
          compiler
          mpi
          netcdf-c
          netcdf-fortran
          fftw
          blas
          cmake
        ]);
        autoloads = "intel openmpi fftw openblas cmake netcdf-c netcdf-fortran";
      };

      devShells.hpcwIntelEctrans = with pkgs; mkDevShell {
        name = "hpcw-intel-ectrans";
        mods = mkModules corePacks (with hpcwIntelEctransPacks.pkgs; [
          compiler
          mpi
          fftw
          blas
          fiat
          cmake
        ]);
        autoloads = "intel openmpi fftw openblas cmake";
      };

      devShells.hpcwIntelIfs = with pkgs; mkDevShell {
        name = "hpcw-intel-ifs";
        mods = mkModules corePacks (with hpcwIntelIfsPacks.pkgs; [
          compiler
          mpi
          fftw
          blas
          python
          eccodes
          cmake
          netcdf-c
          netcdf-fortran
          szip
        ]);
        autoloads = "intel openmpi fftw eccodes openblas cmake python netcdf-c netcdf-fortran";
      };

      devShells.software = with pkgs; mkDevShell {
        name = "slach-software";
        mods = mods_osu;
      };

    })) // {
      lib.findModDeps = pkgs: with inputs.nixpack.lib; with builtins; let
          mods = inputs.nixpkgs.lib.unique (map (x: addPkg x) pkgs);
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

          mkDevShell = {
            name
            , mods
            , autoloads ? ""
            , ...
          }@attrs: with pkgs; let
            in stdenvNoCC.mkDerivation ({
              ENVRC = name;
              nativeBuildInputs = [ bashInteractive ];
              shellHook = ''
                echo_cmd() {
                  echo "+ $@"
                  $@
                }
                echo_cmd source ${corePacks.pkgs.lmod}/lmod/lmod/init/bash
                echo_cmd ml use ${mods}/linux-${corePacks.os}-${corePacks.target}/Core
                echo_cmd ml load ${autoloads}
                echo_cmd ml av
                test -e ~/PS1 && source ~/PS1
                test -e ~/code/git-prompt.sh && source ~/code/git-prompt.sh
                export __git_ps1
              '';
            } // attrs);

          packs = {
            bootstrap = { name = "bootstrap";
              pack = import ./packs/bootstrap.nix {
                inherit corePacks rpmExtern;
                extraConf = import ./hosts/${host}/bootstrap.nix { inherit rpmExtern; pkgs = final.pkgs; };
              };
            };

            core = { name = "core";
              pack = import ./packs/core.nix inputs.nixpack.lib.packs {
                inherit system bootstrapPacks isRLDep rpmExtern;
                pkgs = final.pkgs;
                extraConf = (import ./hosts/${host}/core.nix { inherit rpmExtern inputs; pkgs = final.pkgs; }) // {
                  repos = [
                    (builtins.path { name="hpcw-repo"; path="${inputs.hpcw}/spack/hpcw"; })
                  ];
                };
              };
            };

            intel = { name = "intel";
              pack = corePacks.withPrefs {
                label = "intel";
                repoPatch = {
                  intel-oneapi-compilers = spec: old: {
                    compiler_spec = "intel"; # can be overridden as "intel" with prefs
                    paths = {
                      cc =  "compiler/latest/linux/bin/intel64/icc";
                      cxx = "compiler/latest/linux/bin/intel64/icpc";
                      f77 = "compiler/latest/linux/bin/intel64/ifort";
                      fc =  "compiler/latest/linux/bin/intel64/ifort";
                    };
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
                  ucx = overlaySelf.corePacks.getPackagePrefs "ucx" // {
                    depends.compiler = overlaySelf.corePacks.pkgs.compiler;
                  };
                };
              };
              pkgs = pack: [
                { pkg=pack.pkgs.compiler;
                  projection="intel/{version}";
                  # TODO fix PATH to include legacy compiliers
                }
              ];
            };

            intelOneApi = { name ="intel-oneapi";
              pack = corePacks.withPrefs {
                label = "intel-oneapi";
                repoPatch = {
                  intel-oneapi-compilers = spec: old: {
                    compiler_spec = "oneapi"; # can be overridden as "intel" with prefs
                    paths = {
                      cc =  "compiler/latest/linux/bin/icx";
                      cxx = "compiler/latest/linux/bin/icx";
                      f77 = "compiler/latest/linux/bin/ifx";
                      fc =  "compiler/latest/linux/bin/ifx";
                    };
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
                  ucx = overlaySelf.corePacks.getPackagePrefs "ucx" // {
                    depends.compiler = overlaySelf.corePacks.pkgs.compiler;
                  };
                };
              };
              pkgs = pack: [
                { pkg=pack.pkgs.compiler;
                  projection="oneapi/{version}";
                }
              ];
            };

            aocc = { name ="aocc";
              pack = corePacks.withPrefs {
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
            };
          };
          bootstrapPacks = final.packs.bootstrap.pack;
          corePacks = final.packs.core.pack;
          intelPacks = final.packs.intel.pack;
          intelOneApiPacks = final.packs.intelOneApi.pack;
          aoccPacks = final.packs.aocc.pack;

          mkModules = pack: pkgs: pack.modules (inputs.nixpack.lib.recursiveUpdate modulesConfig ({
            coreCompilers = [ final.corePacks.pkgs.compiler ];
            pkgs = self.lib.findModDeps pkgs;
          }));

          mods_osu = final.mkModules final.corePacks ([
          ]
          ++ (builtins.concatMap (attr: with attr; let
                 pack = (mpis.pack or (x: x)) packs.pack;
                 enabled = (packs.enable or (_: true) attr) && (mpis.enable or (_: true) attr) && (pkgs.enable or (_: true) attr);
               in if ! enabled then [] else
                    (packs.pkgs or (p: []) pack)
                 ++ (pkgs.pkgs pack)
                  )
          (inputs.nixpkgs.lib.cartesianProductOfSets {
            packs = [
              packs.core
              packs.aocc
              packs.intel
              packs.intelOneApi
            ];
            mpis = [
              { name="default"; }
              { name="ompi410";
                enable = attr: builtins.trace "ompi410 cond: ${attr.packs.name} ${toString (attr.packs.name == "core")}" attr.packs.name == "core";
                pack = pack: pack.withPrefs {
                  package.openmpi.version = "4.1.0";
                };
              }
              { name="ompi-cuda";
                enable = attr: builtins.trace "ompi-cuda cond: ${attr.packs.name} ${toString (attr.packs.name == "core")}" attr.packs.name == "core";
                pack = pack: pack.withPrefs {
                  package.openmpi.variants = (pack.getPackagePrefs "openmpi").variants // {
                    cuda = true;
                  };
                  package.ucx.variants = ((pack.getPackagePrefs "ucx").variants or {}) // {
                    cuda = true;
                    gdrcopy = true;
                    rocm = false; # +rocm gdrcopy > 2.0 does not support rocm
                  };
                  package.hwloc.variants = ((pack.getPackagePrefs "hwloc").variants or {}) // {
                    cuda = true;
                  };
                };
              }

            ];
            pkgs = [
              { name = "osu";
                pkgs = pack: with pack.pkgs; [
                  mpi
                  osu-micro-benchmarks
                ];
              }
            ];
          })
          )
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
        })))
      # hpcw configurations
      // (inputs.nixpkgs.lib.listToAttrs (map (attr: with attr; inputs.nixpkgs.lib.nameValuePair (packs.name + variants.name + "Packs") (packs.pack variants.prefs))
        (inputs.nixpkgs.lib.cartesianProductOfSets {
          packs = [
            { name = "hpcwCore";
              pack = prefs: final.corePacks.withPrefs prefs;
            }
            { name = "hpcwIntel";
              pack = prefs: final.intelPacks.withPrefs prefs;
            }
            { name = "hpcwNvhpc";
              pack = prefs: final.corePacks.withPrefs (prefs // {
                package = let
                  core_compiler = { depends.compiler = final.corePacks.pkgs.compiler; };
                in {
                  compiler = { name = "nvhpc"; };
                  nvhpc.variants.blas = false;
                  nvhpc.variants.lapack = false;
                  nvhpc.depends.compiler = final.corePacks.pkgs.compiler;
                } // (prefs.package or {});
                repoPatch = {
                  nvhpc = spec: old: {
                    provides = old.provides or {} // {
                      compiler = ":";
                    };
                    conflicts = [];
                  };
                };
              });
            }
          ];
          variants = [
            { name = ""; prefs = {}; } # default HPCW
            { name = "Ifs";
              prefs = {
                package.python.version = "2";
                package.python.depends.compiler = final.corePacks.pkgs.compiler;
                # eccodes dependency openjpeg: package openjpeg@2.4.0~codec~ipo build_type=RelWithDebInfo does not match dependency constraints {"version":"1.5.0:1.5,2.1.0:2.3"}
                package.openjpeg.version = "2.3";
                package.openjpeg.depends.compiler = final.corePacks.pkgs.compiler;
              };
            }
            { name = "Ectrans";
              prefs = {
                package.ectrans.version = "main";
              };
            }
            { name = "EctransMKL";
              prefs = {
                package.ectrans.version = "main";
                package.ectrans.variants.mkl = true;
              };
            }
            { name = "EctransGpu";
              prefs = {
                package.compiler = { name = "nvhpc"; };
                package.ectrans.version = "gpu";
                package.ectrans.variants.cuda = true;
                # eccodes dependency openjpeg: package openjpeg@2.4.0~codec~ipo build_type=RelWithDebInfo does not match dependency constraints {"version":"1.5.0:1.5,2.1.0:2.3"}
                package.openjpeg.version = "2.3";
              };
            }
            { name = "DwarfPCloudSCGPU";
              prefs = {
                package.dwarf-p-cloudsc.variants.gpu = true;
                package.dwarf-p-cloudsc.variants.cloudsc-gpu-claw = true;
                #package.dwarf-p-cloudsc.variants.hdf5 = false;
                #package.dwarf-p-cloudsc.variants.serialbox = true;
                package.dwarf-p-cloudsc.variants.cloudsc-c = false; # require serialbox?
                package.serialbox.version = "2.5.4-patched"; # require private url (TODO implement curl -n)
              };
            }
            { name = "NemoSmall";
              prefs = {
                #BUILD_COMMAND ./makenemo -a BENCH -m X64_hpcw -j ${NEMO_BUILD_PARALLEL_LEVEL}
                package.nemo.variants.cfg = "BENCH";
                #error: xios dependency boost: package boost@1.72.0~atomic~chrono~clanglibcpp~container~context~contract
                #~coroutine~date_time~debug~exception~fiber~filesystem~graph~graph_parallel~icu~iostreams~json~locale~log
                # ~math~mpi+multithreaded~nowide~numpy~pic~program_options~python~random~regex~serialization+shared~signals
                #~singlethreaded~stacktrace~system~taggedlayout~test~thread~timer~type_erasure~versionedlayout~wave context-impl= cxxstd=98 visibility=hiddeni
                # does not match dependency constraints {"variants":{"atomic":true,"chrono":true,"date_time":true,"exception":true,"filesystem":true,"graph":true,"iostreams":true,"locale":true,"log":true,"math":true,"program_options":true,"random":true,"regex":true,"serialization":true,"signals":true,"system":true,"test":true,"thread":true,"timer":true,"wave":true}}
                package.boost.variants = {
                  atomic = true;
                  chrono = true;
                  date_time = true;exception = true;filesystem = true;graph = true;iostreams = true;locale = true;log = true;math = true;program_options = true;random = true;regex = true;serialization = true;signals = true;system = true;test = true;thread = true;timer = true;wave = true;
                };
              };
            }
            { name = "NemoMedium";
              prefs = {
                #BUILD_COMMAND ./makenemo -m X64_hpcw -n MY_ORCA25 -r ORCA2_ICE_PISCES  -j ${NEMO_BUILD_PARALLEL_LEVEL} del_key "key_top" add_key "key_si3  key_iomput key_mpp_mpi key_mpi2"
                package.nemo.variants.cfg = "ORCA2_ICE_PISCES";
              };
            }
          ];
        })))
      # end of cartesians products
      ;
  };

}
