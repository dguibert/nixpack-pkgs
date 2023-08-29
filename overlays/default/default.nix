final: prev: let
  system = prev.system;
  nocompiler = spec: old: {depends = old.depends or {} // {compiler = null;};};

  lib = import ../../lib {
    lib = (prev.inputs.nixpkgs.inputs.nixpkgs or prev.inputs.nixpkgs).lib;
    nixpack_lib = prev.inputs.nixpack.lib;
  };

  modulesConfig = {
    config = {
      hierarchy = [
        "mpi"
      ];
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
      projections = {
        "ifs nemo=yes" = "{name}-nemo/{version}";
        "ifs nemo=no" = "{name}-nonemo/{version}";
        "cdo ^hdf5" = "{name}/{version}-{^hdf5.name}-{^hdf5.version}";
        "netcdf-c ^hdf5" = "{name}/{version}-{^hdf5.name}-{^hdf5.version}";
        "netcdf-fortran ^hdf5" = "{name}/{version}-{^hdf5.name}-{^hdf5.version}";
        "nemo cfg=ORCA2_ICE_PISCES" = "{name}-orca2_ice_pisces/{version}";
        "nemo cfg=BENCH" = "{name}-bench/{version}";
        "openmpi mca_no_build=btl-openib,btl-uct,btl-usnic,crcp,crs,pml-crcpw,pml-v,snapc,vprotocol" = "{name}-opt/{version}";
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
    inherit (lib) findModDeps;

    hpcw_repo = builtins.path {
      name = "hpcw-repo";
      path = "${inputs.hpcw}/spack/hpcw";
    };
    spack_configs_repo = builtins.path {
      name = "spack-configs-repo";
      path = "${inputs.spack-configs}/repos/bench";
    };

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
              # remove existing module vars/functions
              unset MODULEPATH MODULEPATH_modshare MODULES_CMD MODULESHOME MODULES_RUN_QUARANTINE
              unset -f module module_raw ml

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
            mods = self.mods;
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
        mods = final.mkModules {
          name = label;
          pack = final.pkgs.corePacks;
          pkgs = mod_pkgs;
        };

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

    confPacks = let
      append_pack = suffix: pack: args:
        pack._merge (self:
          with self;
            {
              label = "${pack.label}${suffix}";
            }
            // args);
    in
      lib.listToAttrs (
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
                final.packs.default
                (append_pack "10" packs.gcc {package.gcc.version = "10";})
                (append_pack "11" packs.gcc {package.gcc.version = "11";})
                (append_pack "12" packs.gcc {package.gcc.version = "12";})
                (append_pack "13" packs.gcc {package.gcc.version = "13";})
                packs.aocc
                (append_pack "41" packs.aocc {package.aocc.version = "4.1.0";})
                (append_pack "40" packs.aocc {package.aocc.version = "4.0.0";})
                (append_pack "32" packs.aocc {package.aocc.version = "3.2.0";})
                packs.intel
                packs.llvm
                (append_pack "16" packs.llvm {package.llvm.version = "16";})
                packs.nvhpc
                (append_pack "237" packs.nvhpc {package.nvhpc.version = "23.7";})
                packs.oneapi
              ];
              mpis = [
                (pack: pack)
                (pack:
                  pack._merge (self:
                    with self; {
                      label = "${pack.label}_bmpi";
                      package.mpi = {name = "bull-openmpi";};
                    }))
                (pack:
                  pack._merge (self:
                    with self; {
                      label = "${pack.label}_ompi";
                      package.mpi = {name = "openmpi";};

                      package.openmpi.variants = {
                        cxx = true;
                        legacylaunchers = true;
                        orterunprefix = true;
                        lustre = true;
                        memchecker = false;
                        schedulers.slurm = true;
                        fabrics = {
                          ucx = true;
                          hcoll = true;
                          xpmem = true;
                          cma = true;
                          knem = true;
                        };
                        mca_no_build = {
                          none = false;
                          crs = true;
                          snapc = true;
                          pml-crcpw = true;
                          pml-v = true;
                          vprotocol = true;
                          crcp = true;
                          btl-usnic = true;
                          btl-uct = true;
                          btl-openib = true;
                        };
                      };
                      package.ucx.variants = {
                        cma = true;
                        dc = true;
                        dm = true;
                        logging = false;
                        ib_hw_tm = true;
                        knem = true;
                        mlx5_dv = true;
                        openmp = true;
                        optimizations = true;
                        parameter_checking = false;
                        rc = true;
                        rdmacm = true;
                        thread_multiple = true;
                        ud = true;
                        verbs = true;
                        xpmem = true;
                      };
                      mod_pkgs = with self.pack.pkgs; [
                        compiler
                        {
                          pkg = mpi;
                          projection = "openmpi-opt/{version}";
                        }
                      ];
                    }))
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
                (pack:
                  pack._merge (self: {
                    label = pack.label + "_compiler";
                    mod_pkgs = with self.pack.pkgs; [
                      compiler
                    ];
                  }))
                (import ../../confs/ddfacet.nix final)
                (import ../../confs/emopass.nix final)
                (import ../../confs/hip.nix final)
                (pack: append_pack "54" (import ../../confs/hip.nix final pack) {package.hip.version = "5.4";})
                (pack: append_pack "55" (import ../../confs/hip.nix final pack) {package.hip.version = "5.5.0";})
                (pack: append_pack "56" (import ../../confs/hip.nix final pack) {package.hip.version = "5.6";})
                (import ../../confs/hpcw.nix final)
                (import ../../confs/hpcw-dwarf-p-cloudsc.nix final)
                (import ../../confs/hpcw-dwarf-p-radiation-acraneb2.nix final)
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
                (import ../../confs/jube.nix final)
                (import ../../confs/reframe.nix final)
                (pack:
                  pack._merge (self: {
                    label = pack.label + "_osu";
                    mod_pkgs = with self.pack.pkgs; [
                      osu-micro-benchmarks
                    ];
                  }))
              ];
            })))
        # end of configurations
      );

    corePacks = final.packs.default.pack;
    intelPacks = final.packs.intel.pack;
    intelOneApiPacks = final.packs.oneapi.pack;
    aoccPacks = final.packs.aocc.pack;

    mkModules = {
      name,
      pack,
      pkgs,
      withDeps ? true,
    }:
      pack.modules (inputs.nixpack.lib.recursiveUpdate modulesConfig {
        coreCompilers = [
          pack.pkgs.compiler
        ];
        pkgs =
          if withDeps
          then lib.findModDeps pkgs
          else pkgs;
        name = "modules-${name}";
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

