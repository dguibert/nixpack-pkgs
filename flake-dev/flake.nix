{
  description = "A flake for building packages on /software-like structure";

  inputs = {
    nixpkgs.url          = "github:dguibert/nixpkgs/pu-nixpack";
    #nixpkgs.url          = "github:dguibert/nixpkgs?rev=fa4a95770278b56ca493bafc4496207b9b01eee5";

    #nix.url              = "github:dguibert/nix/a828ef7ec896e4318d62d2bb5fd391e1aabf242e";
    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    nur_dguibert.url     = "github:dguibert/nur-packages/master";
    nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
    nur_dguibert.inputs.nix.follows = "nix";
    nur_dguibert.inputs.flake-utils.follows = "flake-utils";

    #nixpack.url = "github:dguibert/nixpack/pu";
    #nixpack.url = "git+ssh://genji/home_nfs/bguibertd/software-cepp-spack/nixpack?ref=pu";
    nixpack.url = "/home_nfs/bguibertd/software-cepp-spack/nixpack";
    #nixpack.url = "git+file:///tmp/nixpack";
    #nixpack.url = "/tmp/nixpack";
    nixpack.inputs.spack.follows = "spack";
    nixpack.inputs.nixpkgs.follows = "nixpkgs";

    #spack = { url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    #spack = { url = "git+ssh://genji/home_nfs/bguibertd/software-cepp-spack/spack?ref=develop"; flake=false; };
    #spack = { url = "git+https://gitlab.bench.local:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?ref=develop"; flake=false; };
    spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?rev=635b4b4ffedb7c635c63975802955f6ace8b8b7d"; flake=false; };
    #spack = { url = "/home_nfs/bguibertd/software-cepp-spack/spack"; flake=false; };
  };

  outputs = { ... }: { };
}
