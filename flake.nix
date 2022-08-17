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
    (inputs.flake-utils.lib.eachSystem [
        "x86_64-linux"
        /*
         "aarch64-linux"
         */
      ] (system: let
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
            mods = modules.osu;
          };

        devShells.hip = with pkgs;
          mkDevShell {
            name = "slash-hip";
            mods = modules.hip;
            autoloads = "gcc hip openmpi cmake";
          };

        checks =
          {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
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
          }
          // (inputs.flake-utils.lib.flattenTree {
            modules = pkgs.modules;

            hpcw_intel_ectrans = pkgs.confPacks.hpcw_intel_ectrans.mods;
            hpcw_intel_ifs = pkgs.confPacks.hpcw_intel_ifs.mods;
            hpcw_intel_ifs_nonemo = pkgs.confPacks.hpcw_intel_ifs_nonemo.mods;
            hpcw_intel_nemo_small = pkgs.confPacks.hpcw_intel_nemo_small.mods;
            hpcw_intel_impi_ifs_nonemo = pkgs.confPacks.hpcw_intel_impi_ifs_nonemo.mods;
            hpcw_intel_impi_ifs = pkgs.confPacks.hpcw_intel_impi_ifs.mods;
            hpcw_intel_impi_nemo_small = pkgs.confPacks.hpcw_intel_impi_nemo_small.mods;
            hpcw_intel_impi_nemo_medium = pkgs.confPacks.hpcw_intel_impi_nemo_medium.mods;
          });
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
            inherit (self.lib) capture;

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
                          LMOD_PAGER=cat echo_cmd ml av
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
            packs =
              (packs' // host_packs')
              // {
                gcc10 = packs.default._merge (self:
                  with self; {
                    label = "gcc10";
                    package.compiler = packs.default.pack.pkgs.gcc;
                    package.gcc.version = "10";
                  });
              };

            confPacks = inputs.nixpkgs.lib.listToAttrs (
              inputs.nixpkgs.lib.flatten (map (attr:
                  with attr; let
                    pack_ = variants (mpis packs);
                  in [
                    {
                      name = pack_.label;
                      value = pack_;
                    }
                  ])
                ([]
                  # hpcw configurations
                  ++ (inputs.nixpkgs.lib.cartesianProductOfSets {
                    packs = [
                      packs.default
                      packs.intel
                      packs.nvhpc
                    ];
                    mpis = [
                      (pack: pack)
                      (pack:
                        pack._merge (self:
                          with self; {
                            label = "${pack.label}_impi";
                            package.mpi = {name = "intel-mpi";};
                            # for conditionally load all packages with +mpi%compiler
                            package.intel-mpi.depends.compiler = self.pack.pkgs.compiler;
                            repoPatch = {
                              intel-mpi = spec: old: {
                                depends = old.depends // {compiler.deptype = ["build"];};
                              };
                            };
                          }))
                    ];
                    variants = [
                      (import ./confs/hpcw.nix final)
                      (import ./confs/hpcw-dwarf-p-radiation-acraneb2.nix final)
                      (import ./confs/hpcw-dwarf-p-cloudsc.nix final)
                      (import ./confs/hpcw-ecrad.nix final)
                      (import ./confs/hpcw-ectrans.nix final)
                      (pack:
                        (import ./confs/hpcw-ectrans.nix final pack)._merge {
                          label = "hpcw_" + pack.label + "_ectrans_mkl";
                          package.ectrans.variants.mkl = true;
                        })
                      (pack:
                        (import ./confs/hpcw-ectrans.nix final pack)._merge {
                          label = "hpcw_" + pack.label + "_ectrans_gpu";
                          package.ectrans.version = "gpu";
                          package.ectrans.variants.cuda = true;
                          # eccodes dependency openjpeg: package openjpeg@2.4.0~codec~ipo build_type=RelWithDebInfo does not match dependency constraints {"version":"1.5.0:1.5,2.1.0:2.3"}
                          package.openjpeg.version = "2.3";
                        })
                      (pack:
                        (import ./confs/hpcw-ifs.nix final pack)._merge {
                          label = "hpcw_" + pack.label + "_ifs_nonemo";
                          package.ifs.variants.nemo = "no";
                        })
                      (import ./confs/hpcw-ifs.nix final)
                      (import ./confs/hpcw-nemo-small.nix final)
                      (import ./confs/hpcw-nemo-medium.nix final)
                      #(import ./confs/hpcw-nemo-big.nix final)
                    ];
                  })))
              # end of configurations
            );

            hpcw_repo = builtins.path {
              name = "hpcw-repo";
              path = "${inputs.hpcw}/spack/hpcw";
            };

            corePacks = final.packs.default.pack;
            intelPacks = final.packs.intel.pack;
            intelOneApiPacks = final.packs.oneapi.pack;
            aoccPacks = final.packs.aocc.pack;

            mkModules = name: pack: pkgs:
              pack.modules (inputs.nixpack.lib.recursiveUpdate modulesConfig {
                coreCompilers = [
                  pack.pkgs.compiler
                ];
                pkgs = self.lib.findModDeps pkgs;
                name = "modules-${name}";
              });

            modules = recurseIntoAttrs {
              osu = final.mkModules "osu" final.corePacks (
                [
                ]
                ++ (
                  builtins.concatMap
                  (
                    attr:
                      with attr; let
                        pack_ = pkgs (mpis packs);
                        enabled = pack_.enable or true;
                      in
                        if ! enabled
                        then []
                        else (pack_.pkgs or (p: []))
                  )
                  (inputs.nixpkgs.lib.cartesianProductOfSets {
                    packs = [
                      packs.aocc
                      packs.default
                      packs.gcc10
                      packs.intel
                      packs.nvhpc
                      packs.oneapi
                    ];
                    mpis = [
                      (pack: pack._merge {label = pack.label + "_default";})
                      (pack:
                        pack._merge {
                          label = pack.label + "_ompi410";
                          enable = false; #builtins.trace "ompi410 cond: ${pack.name} ${toString (pack.name == "core")}" pack.name == "core";

                          package.openmpi.version = "4.1.0";
                          package.openmpi.variants.pmix = false;
                        })
                      (pack:
                        pack._merge {
                          label = pack.label + "_ompi_cuda";
                          enable = builtins.trace "ompi-cuda cond: ${pack.name} ${toString (pack.name == "core")}" pack.name == "core";

                          package.openmpi.variants.cuda = true;
                          package.ucx.variants = {
                            cuda = true;
                            gdrcopy = true;
                            rocm = false; # +rocm gdrcopy > 2.0 does not support rocm
                          };
                          package.hwloc.variants.cuda = true;
                        })
                    ];
                    pkgs = [
                      (pack:
                        pack._merge (self: {
                          label = pack.label + "_osu";
                          pkgs = with self.pack.pkgs; [
                            mpi
                            osu-micro-benchmarks
                          ];
                        }))
                    ];
                  })
                )
              );

              hip = final.mkModules "hip" final.corePacks (with (packs.default._merge {
                  package.mesa.variants.llvm = false;
                  package.ucx.variants = {
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
                .pack
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
              # hpcw modules
              hpcw_intel_ectrans = pkgs.confPacks.hpcw_intel_ectrans.mods;
              hpcw_intel_ifs = pkgs.confPacks.hpcw_intel_ifs.mods;
              hpcw_intel_ifs_nonemo = pkgs.confPacks.hpcw_intel_ifs_nonemo.mods;
              hpcw_intel_impi_ifs_nonemo = pkgs.confPacks.hpcw_intel_impi_ifs_nonemo.mods;
              hpcw_intel_impi_ifs = pkgs.confPacks.hpcw_intel_impi_ifs.mods;
              hpcw_intel_impi_nemo_small = pkgs.confPacks.hpcw_intel_impi_nemo_small.mods;
              #hpcw_intel_impi_nemo_medium = pkgs.confPacks.hpcw_intel_impi_nemo_medium.mods;
            };

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
        # end of cartesians products
        ;
    };
}
