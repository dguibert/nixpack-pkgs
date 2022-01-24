{
  description = "A flake for building packages on /software-like structure";

  inputs = {
    nixpkgs.url          = "github:dguibert/nixpkgs/pu-cluster";
    #nix.url              = "github:dguibert/nix/pu";
    nix.url              = "github:dguibert/nix/a828ef7ec896e4318d62d2bb5fd391e1aabf242e";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    nur_dguibert.url     = "github:dguibert/nur-packages/master";
    nur_dguibert.inputs.nixpkgs.follows = "nixpkgs";
    nur_dguibert.inputs.nix.follows = "nix";
    nur_dguibert.inputs.flake-utils.follows = "flake-utils";

    nixpack.url = "github:dguibert/nixpack/pu";
    nixpack.inputs.spack.follows = "spack";
    nixpack.inputs.nixpkgs.follows = "nixpkgs";
    #inputs.spack = { url = "git+https://castle.frec.bull.fr:24443/bguibertd/spack.git"; flake=false; };
    spack = { url = "git+https://gitlab:24443/bguibertd/spack.git"; flake=false; };
  };

  outputs = { self, nixpkgs, ... }@inputs: let
      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = system:
        import nixpkgs {
          localSystem = {
            inherit system;
            # gcc = { arch = "x86-64" /*target*/; };
          };
          overlays =  [
            inputs.nix.overlay
            self.overlay
          ];
          config = {
            replaceStdenv = import ../../stdenv.nix;
            allowUnfree = true;
          };
        };

    NIX_CONF_DIR_fun = pkgs: let
      nixConf = pkgs.writeTextDir "opt/nix.conf" ''
        max-jobs = 8
        cores = 0
        sandbox = false
        auto-optimise-store = true
        require-sigs = true
        trusted-users = nixBuild dguibert
        allowed-users = *

        system-features = recursive-nix nixos-test benchmark big-parallel kvm
        sandbox-fallback = false

        keep-outputs = true       # Nice for developers
        keep-derivations = true   # Idem
        extra-sandbox-paths = /opt/intel/licenses=/home/dguibert/nur-packages/secrets?
        experimental-features = nix-command flakes recursive-nix
        system-features = recursive-nix nixos-test benchmark big-parallel gccarch-x86-64
        #extra-platforms = i686-linux aarch64-linux

        builders = @/tmp/nix--home_nfs-bguibertd-machines
      '';
    in
      "${nixConf}/opt";

  in (inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
       let pkgs = nixpkgsFor system;
       in rec {

    legacyPackages = pkgs;

    devShell = with pkgs; mkShell rec {
      name = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      ENVRC = "nix-${builtins.replaceStrings [ "/" ] [ "-" ] nixStore}";
      nativeBuildInputs = [ pkgs.nix jq
      ];
      shellHook = ''
        export ENVRC=${name}
        export XDG_CACHE_HOME=$HOME/.cache/${name}
        export NIX_STORE=${nixStore}/store
        unset TMP TMPDIR TEMPDIR TEMP
        unset NIX_PATH

      '';
      NIX_CONF_DIR = NIX_CONF_DIR_fun pkgs;
    };

  })) // {
    overlay = final: prev: {
    };
  };

}
