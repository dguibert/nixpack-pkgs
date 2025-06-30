{
  description = "A flake for building packages on /software-like structure";

  inputs.nixpkgs.url = "flake:nixpkgs"; # use registry nixpkgs, could be "github:dguibert/nur-packages";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs/nixpkgs";
  inputs.flake-utils.follows = "nixpkgs/flake-utils";

  inputs.nixpack.url = "github:dguibert/nixpack/pu";
  inputs.nixpack.inputs.spack.follows = "spack";
  inputs.nixpack.inputs.nixpkgs.follows = "nixpkgs";
  inputs.spack.url = "github:dguibert/spack/develop";
  inputs.spack.flake = false;
  inputs.spackPkgs.url = "github:dguibert/spack/develop";
  inputs.spackPkgs.flake = false;
  #inputs.hpcw = {
  #  #url = "git+ssh://spartan/home_nfs/bguibertd/work/hpcw?ref=dg/spack";
  #  url = "git+https://castle.frec.bull.fr:24443/cepp/apps/hpcw/hpcw?ref=master";
  #  #url = "git@gitlab.dkrz.de:esiwace/hpcw.git";
  #  flake = false;
  #};
  inputs.cbm-spack = {
    url = "github:dguibert/compbiomed-spack?ref=dg/hemepure";
    flake = false;
  };
  #inputs.spack-configs = {
  #  url = "git+https://castle.frec.bull.fr:24443/cepp/scripts-tools/spack-configs.git";
  #  flake = false;
  #};

  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  inputs.pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";

  nixConfig.pure-eval = true;
  nixConfig.sandbox = false;

  outputs = inputs @ {
    self,
    flake-utils,
    flake-parts,
    nixpkgs,
    nixpack,
    spack,
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
        ./overlays/default.nix
        ./modules/all-modules.nix
        #./lib
        #./apps
        ./envs
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
