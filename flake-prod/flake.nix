{
  description = "A flake for building packages on /software-like structure";

  inputs = {
    #nixpkgs.url          = "github:dguibert/nixpkgs/pu-nixpack";
    nixpkgs.url          = "github:dguibert/nixpkgs?rev=fcc37bb4977ad0866db6c9218a80278ae6f2f822";

    nix.url              = "github:dguibert/nix/pu";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    nur_dguibert.url     = "github:dguibert/nur-packages/pu";
    nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
    nur_dguibert.inputs.nix.follows = "nix";
    nur_dguibert.inputs.flake-utils.follows = "flake-utils";

    nixpack.url = "github:dguibert/nixpack/pu";
    nixpack.inputs.spack.follows = "spack";
    nixpack.inputs.nixpkgs.follows = "nixpkgs";

    #spack = { url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    #spack = { url = "git+https://gitlab.bench.local:24443/bguibertd/spack.git?ref=develop"; flake=false; };
    spack = { url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop&rev=fb1f5ad322d3fea18d53659020c21123bcdaf3a8"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?ref=develop"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack"; flake=false; };
  };

  outputs = { ... }: { };
}
