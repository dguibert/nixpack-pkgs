{
  description = "A flake for building packages on /software-like structure";

  inputs.nixpkgs.url = "github:dguibert/nur-packages/host/spartan";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";
  inputs.flake-utils.follows = "nixpkgs/flake-utils";

  inputs.nixpack.url = "github:dguibert/nixpack/pu";
  inputs.nixpack.inputs.spack.follows = "spack";
  inputs.nixpack.inputs.nixpkgs.follows = "nixpkgs";
  inputs.spack.url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop";
  inputs.spack.flake = false;
  inputs.hpcw = {
    #url = "git+ssh://spartan/home_nfs/bguibertd/work/hpcw?ref=dg/spack";
    url = "git+https://castle.frec.bull.fr:24443/cepp/apps/hpcw/hpcw?ref=dg/spack";
    #url = "git@gitlab.dkrz.de:esiwace/hpcw.git";
    flake = false;
  };

  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";

  outputs = inputs @ {
    self,
    flake-utils,
    flake-parts,
    nixpkgs,
    nixpack,
    spack,
    hpcw,
    ...
  }: let
    inherit (self) outputs;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        #"aarch64-linux"
      ];
      imports = [
        ./modules/all-modules.nix
        #./lib
        #./apps
        ./checks
        ./shells
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
      };
      flake = {
      };
    };
}
#        devShells.software = with pkgs;
#          mkDevShell {
#            name = "slash-software";
#            mods = modules.osu;
#          };
#
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

