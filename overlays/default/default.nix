final: prev: let
  system = prev.system;
  nocompiler = spec: old: {depends = old.depends or {} // {compiler = null;};};

  lib = import ../../lib {
    lib = (prev.inputs.nixpkgs.inputs.nixpkgs or prev.inputs.nixpkgs).lib;
    nixpack_lib = prev.inputs.nixpack.lib;
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

  overlaySelf = with overlaySelf;
  with prev; {
    inherit (lib) isLDep isRDep isRLDep;
    inherit (lib) rpmVersion rpmExtern;
    inherit (lib) packsFun loadPacks virtual;
    inherit (lib) capture;

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
          inherit os system label global spackConfig repos repoPatch package spackPython spackEnv spackShell;
        };
        inherit system;
        spackShell = "/bin/bash";

        global = {
          verbose = true;
          fixedDeps = true;
          resolver = null;
        };

        spackConfig.config.url_fetch_method = "curl";
        repos = [];
        repoPatch = {};
        package = {};

        devShell = with final.pkgs;
          mkDevShell {
            name = label;
            inherit mods;
            autoloads = lib.concatMapStrings (x: let
              pkg = x.pkg or x;
              name =
                if x ? projection
                then "${builtins.head (builtins.split "/(.*)" x.projection)} "
                else "${(builtins.parseDrvName (pack.getPackage pkg).spec.compiler_spec).name} ";
            in
              if x ? autoload
              then
                if x.autoload
                then name
                else ""
              else name)
            mod_pkgs;
          };
        mods = final.mkModules label final.pkgs.corePacks mod_pkgs;

        mod_pkgs = [];
        img_pkgs = mod_pkgs;

        sifImg = final.pkgs.singularity-tools.buildImage {
          name = label;
          diskSize = 16384;
          contents =
            map (
              x: let
                pkg = x.pkg or x;
              in
                if pkg ? spec && pkg.spec.extern == null
                then pkg
                else builtins.trace "WARNING: external package ${pkg.name}" []
              /*
              FIXME might be a problem to rely on an external package inside the image
              */
            )
            img_pkgs;
        };

        dockerImg = final.pkgs.dockerTools.buildImage {
          name = label;
          contents =
            map (
              x: let
                pkg = x.pkg or x;
              in
                if pkg ? spec && pkg.spec.extern == null
                then pkg
                else builtins.trace "WARNING: external package ${pkg.name}" []
              /*
              FIXME might be a problem to rely on an external package inside the image
              */
            )
            img_pkgs;
        };
      });

    packs' = lib.loadPacks prev ../../packs;
    host_packs' = {}; # entry point for overriding packs'
    packs =
      (packs' // host_packs')
      // {
        gcc10 = packs.default._merge (self:
          with self; {
            label = "gcc10";
            package.compiler = packs.default.pack.pkgs.gcc.withPrefs {version = "10";};
            #compiler = corePacks.pkgs.gcc.withPrefs { version = "10"; };
            package.gcc.version = "10";
          });
      };

    confPacks = lib.listToAttrs (
      lib.flatten (map (attr:
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
          ++ (lib.cartesianProductOfSets {
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
              (import ../../confs/hip.nix final)
              (import ../../confs/jube.nix final)
              (import ../../confs/hpcw.nix final)
              (import ../../confs/hpcw-dwarf-p-radiation-acraneb2.nix final)
              (import ../../confs/hpcw-dwarf-p-cloudsc.nix final)
              (import ../../confs/hpcw-ecrad.nix final)
              (import ../../confs/hpcw-ectrans.nix final)
              (pack:
                (import ../../confs/hpcw-ectrans.nix final pack)._merge {
                  label = "hpcw_" + pack.label + "_ectrans_mkl";
                  package.ectrans.variants.mkl = true;
                })
              (pack:
                (import ../../confs/hpcw-ectrans.nix final pack)._merge {
                  label = "hpcw_" + pack.label + "_ectrans_gpu";
                  package.ectrans.version = "gpu";
                  package.ectrans.variants.cuda = true;
                })
              (pack:
                (import ../../confs/hpcw-ifs.nix final pack)._merge {
                  label = "hpcw_" + pack.label + "_ifs_nonemo";
                  package.ifs.variants.nemo = "no";
                })
              (import ../../confs/hpcw-icon.nix final)
              (import ../../confs/hpcw-ifs.nix final)
              (import ../../confs/hpcw-ifs-fvm.nix final)
              (import ../../confs/hpcw-nemo-small.nix final)
              (import ../../confs/hpcw-nemo-medium.nix final)
              #(import ../../confs/hpcw-nemo-big.nix final)
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
        pkgs = lib.findModDeps pkgs;
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
          (lib.cartesianProductOfSets {
            packs = [
              # packs.aocc # fails spack-src/c/mpi/pt2pt/../../../c/util/osu_util_papi.h:25: multiple definition of `omb_papi_output_filename'
              packs.default
              # packs.gcc10# fails spack-src/c/mpi/pt2pt/../../../c/util/osu_util_papi.h:25: multiple definition of `omb_papi_output_filename'
              packs.intel
              packs.nvhpc
              # packs.oneapi # fails spack-src/c/mpi/pt2pt/../../../c/util/osu_util_papi.h:25: multiple definition of `omb_papi_output_filename'
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
                  enable = false; # TODO fix ucx duplicate #builtins.trace "ompi-cuda cond: ${pack.name} ${toString (pack.name == "core")}" pack.name == "core";

                  package.openmpi.variants.cuda = true;
                  package.ucx.variants = {
                    extern =
                      if
                        (pack.package.ucx.variants.cuda
                          != true)
                        || (pack.package.ucx.variants.gdrcopy != true)
                      then null
                      else pack.package.ucx.extern;
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
  // (lib.listToAttrs (map (attr:
      with attr; {
        name = packs.name + variants.name + "Packs_" + grid + "_" + processors;
        value = packs.pack grid processors variants.v;
      })
    (lib.cartesianProductOfSets {
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

