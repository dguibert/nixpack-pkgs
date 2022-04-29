{
  description = "A flake for building packages on /software-like structure";

  inputs = {
    #nixpkgs.url          = "github:dguibert/nixpkgs/pu";
    nixpkgs.url          = "github:dguibert/nixpkgs?rev=bc2ea7d294f0dc159251283eb5bee80c137fa9ca";

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
    spack = { url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git?ref=develop&rev=2221070706bf6ad4712d4b1c0b5e590179b11f6c"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack?ref=develop"; flake=false; };
    #spack = { url = "git+file:///home_nfs/bguibertd/software-cepp-spack/spack"; flake=false; };
  };

  outputs = { ... }: { };
}
