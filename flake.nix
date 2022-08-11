{
  description = "A flake for building packages on /software-like structure";

  inputs.nixpkgs.url = "github:dguibert/nixpkgs/pu-nixpack";
  inputs.nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nur_dguibert.inputs.nix.follows = "nix";
  inputs.nur_dguibert.inputs.flake-utils.follows = "flake-utils";

  inputs.nixpack.inputs.spack.follows = "spack";
  inputs.nixpack.inputs.nixpkgs.follows = "nixpkgs";
  inputs.spack.flake = false;
  inputs.hpcw = {
    url = "git+file:///home_nfs/bguibertd/work/hpcw?ref=refs%2fheads%2fdg%2fspack";
    flake = false;
  };

  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    self,
    nixpkgs,
    nix,
    flake-utils,
    nur_dguibert,
    nixpack,
    spack,
    hpcw,
    ...
  } @ inputs: let
    host = "genji";
    #host = "nixos";
    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = system:
      import nixpkgs {
        localSystem = {
          inherit system;
          # gcc = { arch = "x86-64" /*target*/; };
        };
        overlays =
          [
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
  in
    (inputs.flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: let
      pkgs = nixpkgsFor system;
    in rec {
      legacyPackages = pkgs;

      devShells.default = with pkgs;
        mkDevShell {
          name = "pkgs";
          mods = [];
          shellHook = ''
            ${inputs.self.checks.${system}.pre-commit-check.shellHook}
          '';
        };

      devShells.software = with pkgs;
        mkDevShell {
          name = "slash-software";
          mods = mods_osu;
        };

      devShells.hip = with pkgs;
        mkDevShell {
          name = "slash-hip";
          mods = mods_hip;
          autoloads = "gcc hip openmpi cmake";
        };

      checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          #nixpkgs-fmt.enable = true;
          alejandra.enable = true; # https://github.com/kamadorueda/alejandra/blob/main/integrations/pre-commit-hooks-nix/README.md
          prettier.enable = true;
          trailing-whitespace = {
            enable = true;
            name = "trim trailing whitespace";
            entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/trailing-whitespace-fixer";
            types = ["text"];
            stages = ["commit" "push" "manual"];
          };
          check-merge-conflict = {
            enable = true;
            name = "check for merge conflicts";
            entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/check-merge-conflict";
            types = ["text"];
          };
        };
      };
    }))
    // {
      lib = import ./lib {
        lib = inputs.nixpkgs.lib;
        nixpack_lib = inputs.nixpack.lib;
      };

      overlay =
        final: prev: let
          system = prev.system;
          nocompiler = spec: old: {depends = old.depends or {} // {compiler = null;};};

          overlaySelf = with overlaySelf;
          with prev; {
            inherit (self.lib) isLDep isRDep isRLDep;
            inherit (self.lib) rpmVersion rpmExtern;
            inherit (self.lib) packsFun loadPacks virtual;

            mkDevShell = {
              name,
              mods,
              autoloads ? "",
              ...
            } @ attrs:
              with pkgs; let
              in
                stdenvNoCC.mkDerivation ({
                    ENVRC = name;
                    nativeBuildInputs = [bashInteractive];
                    shellHook = ''
                      echo_cmd() {
                        echo "+ $@"
                        $@
                      }
                      echo_cmd source ${corePacks.pkgs.lmod}/lmod/lmod/init/bash
                      ${
                        if mods != []
                        then ''
                          echo_cmd ml use ${mods}/linux-${corePacks.os}-${corePacks.target}/Core
                          ${
                            if autoloads != ""
                            then "echo_cmd ml load ${autoloads}"
                            else ""
                          }
                          echo_cmd ml av
                        ''
                        else ""
                      }
                      test -e ~/PS1 && source ~/PS1
                      test -e ~/code/git-prompt.sh && source ~/code/git-prompt.sh
                      export __git_ps1

                      ${attrs.shellHook or ""}
                    '';
                  }
                  // (builtins.removeAttrs attrs ["shellHook"]));

            default_pack = virtual (self:
              with self; {
                name = label;
                pack = packsFun {
                  inherit os system label global spackConfig repos repoPatch package spackPython spackEnv;
                };
                inherit system;

                global = {
                  verbose = true;
                  fixedDeps = true;
                  resolver = null;
                };

                spackConfig.config.url_fetch_method = "curl";
                repos = [];
                repoPatch = {};
                package = {};
              });

            packs' = self.lib.loadPacks prev ./packs;
            host_packs' = self.lib.loadPacks prev ./hosts/${host};
            packs = packs' // host_packs';

            hpcw_repo = builtins.path {
              name = "hpcw-repo";
              path = "${inputs.hpcw}/spack/hpcw";
            };

            corePacks = final.packs.default.pack;
            intelPacks = final.packs.intel.pack;
            intelOneApiPacks = final.packs.oneapi.pack;
            aoccPacks = final.packs.aocc.pack;

            mkModules = pack: pkgs:
              pack.modules (inputs.nixpack.lib.recursiveUpdate modulesConfig {
                coreCompilers = [
                  pack.pkgs.compiler
                ];
                pkgs = self.lib.findModDeps pkgs;
              });

            mods_osu = final.mkModules final.corePacks (
              [
              ]
              ++ (
                builtins.concatMap
                (
                  attr:
                    with attr; let
                      pack = (mpis.pack or (x: x)) packs.pack;
                      enabled = (packs.enable or (_: true) attr) && (mpis.enable or (_: true) attr) && (pkgs.enable or (_: true) attr);
                    in
                      if ! enabled
                      then []
                      else
                        (packs.pkgs or (p: []) pack)
                        ++ (pkgs.pkgs pack)
                )
                (inputs.nixpkgs.lib.cartesianProductOfSets {
                  packs = [
                    packs.default
                    packs.aocc
                    packs.intel
                    packs.oneapi
                  ];
                  mpis = [
                    {name = "default";}
                    {
                      name = "ompi410";
                      enable = attr: builtins.trace "ompi410 cond: ${attr.packs.name} ${toString (attr.packs.name == "core")}" attr.packs.name == "core";
                      pack = pack:
                        pack.withPrefs {
                          package.openmpi.version = "4.1.0";
                        };
                    }
                    {
                      name = "ompi-cuda";
                      enable = attr: builtins.trace "ompi-cuda cond: ${attr.packs.name} ${toString (attr.packs.name == "core")}" attr.packs.name == "core";
                      pack = pack:
                        pack.withPrefs {
                          package.openmpi.variants =
                            (pack.getPackagePrefs "openmpi").variants
                            // {
                              cuda = true;
                            };
                          package.ucx.variants =
                            ((pack.getPackagePrefs "ucx").variants or {})
                            // {
                              cuda = true;
                              gdrcopy = true;
                              rocm = false; # +rocm gdrcopy > 2.0 does not support rocm
                            };
                          package.hwloc.variants =
                            ((pack.getPackagePrefs "hwloc").variants or {})
                            // {
                              cuda = true;
                            };
                        };
                    }
                  ];
                  pkgs = [
                    {
                      name = "osu";
                      pkgs = pack:
                        with pack.pkgs; [
                          mpi
                          osu-micro-benchmarks
                        ];
                    }
                  ];
                })
              )
            );

            mods_hip = final.mkModules final.corePacks (with (corePacks.withPrefs {
                package.mesa.variants.llvm = false;
                package.ucx.variants =
                  ((corePacks.getPackagePrefs "ucx").variants or {})
                  // {
                    cuda = true;
                    gdrcopy = false;
                    rocm = true; # +rocm gdrcopy > 2.0 does not support rocm
                  };

                repoPatch = {
                  llvm-amdgpu = spec: old: {
                    provides =
                      old.provides
                      or {}
                      // {
                        compiler = null;
                      };
                  };
                };
              })
              .pkgs; [
                compiler
                mpi
                hip
                {
                  pkg = llvm-amdgpu;
                  context.provides = []; # not real compiler
                }
                #(hip.withPrefs { package.mesa.variants.llvm = false; }) # https://github.com/spack/spack/issues/30611
                #hipfft
                cmake
                cuda
              ]);

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
        in
          overlaySelf
          # blom configurations
          // (inputs.nixpkgs.lib.listToAttrs (map (attr:
              with attr; {
                name = packs.name + variants.name + "Packs_" + grid + "_" + processors;
                value = packs.pack grid processors variants.v;
              })
            (inputs.nixpkgs.lib.cartesianProductOfSets {
              packs = [
                {
                  name = "blomIntelOrig";
                  pack = grid: processors: v:
                    final.intelPacks.withPrefs {
                      repoPatch = {
                        intel-parallel-studio = spec: old: {
                          compiler_spec = "intel@19.1.1.217";
                          provides =
                            old.provides
                            or {}
                            // {
                              compiler = ":";
                            };
                          depends =
                            old.depends
                            or {}
                            // {
                              compiler = null;
                            };
                        };
                      };
                      package.compiler = {
                        name = "intel-parallel-studio";
                        version = "professional.2020.1";
                      };
                      package.intel-parallel-studio.variants.mpi = false;
                      package.mpi = {
                        name = "intel-mpi";
                        version = "2019.7.217";
                      };
                      package.blom = {
                        version = "local";
                        variants = let
                          self =
                            {
                              inherit grid processors;
                              mpi = true;
                              parallel_netcdf = true;
                              buildtype = "release";
                            }
                            // (v self);
                        in
                          self;
                      };
                    };
                }

                {
                  name = "blomOneApi";
                  pack = grid: processors: v:
                    final.intelOneApiPacks.withPrefs {
                      package.mpi = {name = "intel-oneapi-mpi";};
                      package.blom = {
                        version = "local";
                        variants = let
                          self =
                            {
                              inherit grid processors;
                              mpi = true;
                              parallel_netcdf = true;
                              buildtype = "release";
                            }
                            // (v self);
                        in
                          self;
                      };
                    };
                }
                {
                  name = "blomIntel";
                  pack = grid: processors: v:
                    final.intelPacks.withPrefs {
                      package.mpi = {name = "intel-oneapi-mpi";};
                      package.blom = {
                        version = "local";
                        variants = let
                          self =
                            {
                              inherit grid processors;
                              mpi = true;
                              parallel_netcdf = true;
                              buildtype = "release";
                            }
                            // (v self);
                        in
                          self;
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
                {
                  name = "";
                  v = variants: {};
                }
                {
                  name = "Opt0";
                  v = variants:
                    with variants; {
                      optims.no = false;
                      optims.opt0 = true;
                      optims.opt1 = false;
                      optims.opt2 = false;
                    };
                }
                {
                  name = "Opt1";
                  v = variants:
                    with variants; {
                      optims.no = false;
                      optims.opt1 = true;
                      optims.opt2 = false;
                    };
                }
                {
                  name = "Opt2";
                  v = variants:
                    with variants; {
                      optims.no = false;
                      optims.opt1 = false;
                      optims.opt2 = true;
                    };
                }
                {
                  name = "SafeOpts";
                  v = variants:
                    with variants; {
                      optims.no = false;
                      optims.opt0 = true;
                      optims.opt1 = true;
                      optims.opt2 = false;
                    };
                }
                {
                  name = "Opts";
                  v = variants:
                    with variants; {
                      optims.no = false;
                      optims.opt0 = true;
                      optims.opt1 = true;
                      optims.opt2 = true;
                    };
                }
              ];
            })))
          # hpcw configurations
          // (inputs.nixpkgs.lib.listToAttrs (inputs.nixpkgs.lib.flatten (map (attr:
              with attr; [
                {
                  name = packs.name + variants.name + "Packs";
                  value = packs.pack variants.prefs;
                }
                {
                  name = packs.name + variants.name + "DevShell";
                  value = variants.devShell final."${packs.name + variants.name + "Packs"}";
                }
              ])
            (inputs.nixpkgs.lib.cartesianProductOfSets {
              packs = [
                {
                  name = "hpcwCore";
                  pack = prefs: final.corePacks.withPrefs prefs;
                }
                {
                  name = "hpcwIntel";
                  pack = prefs: final.intelPacks.withPrefs prefs;
                }
                {
                  name = "hpcwNvhpc";
                  pack = prefs:
                    final.corePacks.withPrefs (prefs
                      // {
                        package = let
                          core_compiler = {depends.compiler = final.corePacks.pkgs.compiler;};
                        in
                          {
                            compiler = {name = "nvhpc";};
                            nvhpc.variants.blas = false;
                            nvhpc.variants.lapack = false;
                            nvhpc.depends.compiler = final.corePacks.pkgs.compiler;
                          }
                          // (prefs.package or {});
                        repoPatch = {
                          nvhpc = spec: old: {
                            provides =
                              old.provides
                              or {}
                              // {
                                compiler = ":";
                              };
                            conflicts = [];
                          };
                        };
                      });
                }
              ];
              variants = [
                {
                  name = "";
                  prefs = {};
                } # default HPCW
                {
                  name = "Ifs";
                  prefs = {
                    package.python.version = "2";
                    package.python.depends.compiler = final.corePacks.pkgs.compiler;
                    # eccodes dependency openjpeg: package openjpeg@2.4.0~codec~ipo build_type=RelWithDebInfo does not match dependency constraints {"version":"1.5.0:1.5,2.1.0:2.3"}
                    package.openjpeg.version = "2.3";
                    package.openjpeg.depends.compiler = final.corePacks.pkgs.compiler;
                  };
                  devShell = pack:
                    with final.pkgs;
                      mkDevShell {
                        name = "hpcw-ifs";
                        mods = mkModules corePacks (with pack.pkgs; [
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
                          ifs
                        ]);
                        autoloads = "intel openmpi fftw eccodes openblas cmake python netcdf-c netcdf-fortran";
                      };
                }
                {
                  name = "Ecrad";
                  prefs = {};
                  devShell = pack:
                    with final.pkgs;
                      mkDevShell {
                        name = "hpcw-ecrad";
                        mods = mkModules corePacks (with pack.pkgs; [
                          compiler
                          mpi
                          netcdf-c
                          netcdf-fortran
                          fftw
                          blas
                          cmake
                          ecrad
                        ]);
                        autoloads = "intel openmpi fftw openblas cmake netcdf-c netcdf-fortran";
                      };
                }

                {
                  name = "Ectrans";
                  prefs = {
                    package.ectrans.version = "main";
                  };
                  devShell = pack:
                    with final.pkgs;
                      mkDevShell {
                        name = "hpcw-ectrans";
                        mods = mkModules corePacks (with pack.pkgs; [
                          compiler
                          mpi
                          fftw
                          blas
                          fiat
                          cmake
                          ectrans
                        ]);
                        autoloads = "intel openmpi fftw openblas cmake";
                      };
                }
                {
                  name = "EctransMKL";
                  prefs = {
                    package.ectrans.version = "main";
                    package.ectrans.variants.mkl = true;
                  };
                }
                {
                  name = "EctransGpu";
                  prefs = {
                    package.compiler = {name = "nvhpc";};
                    package.ectrans.version = "gpu";
                    package.ectrans.variants.cuda = true;
                    # eccodes dependency openjpeg: package openjpeg@2.4.0~codec~ipo build_type=RelWithDebInfo does not match dependency constraints {"version":"1.5.0:1.5,2.1.0:2.3"}
                    package.openjpeg.version = "2.3";
                  };
                }
                {
                  name = "DwarfPCloudSCGPU";
                  prefs = {
                    package.dwarf-p-cloudsc.variants.gpu = true;
                    package.dwarf-p-cloudsc.variants.cloudsc-gpu-claw = true;
                    #package.dwarf-p-cloudsc.variants.hdf5 = false;
                    #package.dwarf-p-cloudsc.variants.serialbox = true;
                    package.dwarf-p-cloudsc.variants.cloudsc-c = false; # require serialbox?
                    package.serialbox.version = "2.5.4-patched"; # require private url (TODO implement curl -n)
                  };
                }
                {
                  name = "NemoSmall";
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
                      date_time = true;
                      exception = true;
                      filesystem = true;
                      graph = true;
                      iostreams = true;
                      locale = true;
                      log = true;
                      math = true;
                      program_options = true;
                      random = true;
                      regex = true;
                      serialization = true;
                      signals = true;
                      system = true;
                      test = true;
                      thread = true;
                      timer = true;
                      wave = true;
                    };
                  };
                  devShell = pack:
                    with final.pkgs;
                      mkDevShell {
                        name = "hpcw-nemo-small";
                        mods = mkModules corePacks (with pack.pkgs; [
                          compiler
                          mpi
                          xios
                          cmake
                          nemo
                          pkgconf # for hdf5?
                        ]);
                        autoloads = "intel openmpi xios cmake";
                      };
                }
                {
                  name = "NemoMedium";
                  prefs = {
                    #BUILD_COMMAND ./makenemo -m X64_hpcw -n MY_ORCA25 -r ORCA2_ICE_PISCES  -j ${NEMO_BUILD_PARALLEL_LEVEL} del_key "key_top" add_key "key_si3  key_iomput key_mpp_mpi key_mpi2"
                    package.nemo.variants.cfg = "ORCA2_ICE_PISCES";
                  };
                  devShell = pack:
                    with final.pkgs;
                      mkDevShell {
                        name = "hpcw-nemo-medium";
                        mods = mkModules corePacks (with pack.pkgs; [
                          compiler
                          mpi
                          xios
                          cmake
                          nemo
                          pkgconf # for hdf5?
                        ]);
                        autoloads = "intel openmpi xios cmake";
                      };
                }
              ];
            }))))
        # end of cartesians products
        ;
    };
}
