{
  description = "A flake for building packages on /software-like structure";

  inputs.nixpkgs.url = "github:dguibert/nur-packages/host/spartan";

  inputs.nixpack.url = "github:dguibert/nixpack/pu";
  inputs.nixpack.inputs.spack.follows = "spack";
  inputs.nixpack.inputs.nixpkgs.follows = "nixpkgs";
  inputs.spack.url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop";
  inputs.spack.flake = false;
  inputs.hpcw = {
    #url = "git+ssh://spartan/home_nfs/bguibertd/work/hpcw?ref=dg/spack";
    url = "git+file:///home_nfs/bguibertd/work/hpcw?ref=dg/spack";
    flake = false;
  };

  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ self, flake-utils, flake-parts, nixpkgs, nixpack, spack, hpcw,... }: let
    inherit (self) outputs;

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
  in flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    imports = [
      ./modules/all-modules.nix
      #./lib
      #./apps
      ./checks
      ./shells
    ];

    perSystem = {config, self', inputs', pkgs, system, ...}: {
    };
    flake = {
    };
  };
}
#        devShells.default = with pkgs;
#          mkDevShell {
#            name = "pkgs";
#            mods = [];
#            shellHook = ''
#              ${inputs.self.checks.${system}.pre-commit-check.shellHook}
#            '';
#          };
#
#        devShells.software = with pkgs;
#          mkDevShell {
#            name = "slash-software";
#            mods = modules.osu;
#          };
#
#        checks =
#          {
#            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
#              src = ./.;
#              hooks = {
#                #nixpkgs-fmt.enable = true;
#                alejandra.enable = true; # https://github.com/kamadorueda/alejandra/blob/main/integrations/pre-commit-hooks-nix/README.md
#                prettier.enable = true;
#                trailing-whitespace = {
#                  enable = true;
#                  name = "trim trailing whitespace";
#                  entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/trailing-whitespace-fixer";
#                  types = ["text"];
#                  stages = ["commit" "push" "manual"];
#                };
#                check-merge-conflict = {
#                  enable = true;
#                  name = "check for merge conflicts";
#                  entry = "${pkgs.python3.pkgs.pre-commit-hooks}/bin/check-merge-conflict";
#                  types = ["text"];
#                };
#              };
#            };
#          }
#          // (inputs.flake-utils.lib.flattenTree {
#            modules = pkgs.modules;
#
#            hpcw_intel_acraneb2 = pkgs.confPacks.hpcw_intel_acraneb2.mods;
#            hpcw_intel_ectrans = pkgs.confPacks.hpcw_intel_ectrans.mods;
#            hpcw_intel_ifs = pkgs.confPacks.hpcw_intel_ifs.mods;
#            hpcw_intel_ifs_nonemo = pkgs.confPacks.hpcw_intel_ifs_nonemo.mods;
#            hpcw_intel_nemo_small = pkgs.confPacks.hpcw_intel_nemo_small.mods;
#            hpcw_intel_impi_ecrad = pkgs.confPacks.hpcw_intel_ecrad.mods;
#            hpcw_intel_impi_icon = pkgs.confPacks.hpcw_intel_icon.mods;
#            hpcw_intel_impi_ifs_nonemo = pkgs.confPacks.hpcw_intel_impi_ifs_nonemo.mods;
#            hpcw_intel_impi_ifs = pkgs.confPacks.hpcw_intel_impi_ifs.mods;
#            hpcw_intel_impi_ifs-fvm = pkgs.confPacks.hpcw_intel_impi_ifs-fvm.mods; # FIXME ifs-fvm requires to be built on 1 core only
#            hpcw_intel_impi_nemo_small = pkgs.confPacks.hpcw_intel_impi_nemo_small.mods;
#            hpcw_intel_impi_nemo_medium = pkgs.confPacks.hpcw_intel_impi_nemo_medium.mods;
#
#            hpcw_nvhpc_cloudsc = pkgs.confPacks.hpcw_nvhpc_cloudsc.mods;
#          });
#      }))
#    // {
#      lib = import ./lib {
#        lib = inputs.nixpkgs.lib;
#        nixpack_lib = inputs.nixpack.lib;
#      };
#
#      overlays.default =
#}
