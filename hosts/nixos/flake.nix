{
  description = "A flake for building my NIXPACK packages";

  ## local dev
  inputs.upstream.url = "path:../..";
  # inputs.upstream.url = "github:dguibert/nixpack-pkgs/main";
  inputs.upstream.inputs.nixpkgs.follows = "nixpkgs";
  #inputs.nixpkgs.url = "github:dguibert/nur-packages?dir=nixpkgs/default";
  inputs.nixpkgs.url = "github:dguibert/nur-packages/master";
  inputs.flake-utils.follows = "upstream/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    upstream,
    ...
  } @ inputs: let
    nixpkgsFor = system:
      import upstream.inputs.nixpkgs.inputs.nixpkgs {
        inherit system;
        overlays =
          upstream.legacyPackages.${system}.overlays
          ++ [
            self.overlays.default
          ];
        config = upstream.legacyPackages.${system}.config;
      };
  in
    (flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = nixpkgsFor system;
    in {
      legacyPackages = pkgs;
      checks =
        {
        }
        // (inputs.flake-utils.lib.flattenTree {
          #modules = pkgs.modules;

          #hpcw_intel_acraneb2 = pkgs.confPacks.hpcw_intel_acraneb2.mods;
          #hpcw_intel_ectrans = pkgs.confPacks.hpcw_intel_ectrans.mods;
          #hpcw_intel_ifs = pkgs.confPacks.hpcw_intel_ifs.mods;
          #hpcw_intel_ifs_nonemo = pkgs.confPacks.hpcw_intel_ifs_nonemo.mods;
          #hpcw_intel_nemo_small = pkgs.confPacks.hpcw_intel_nemo_small.mods;
          #hpcw_intel_impi_ecrad = pkgs.confPacks.hpcw_intel_ecrad.mods;
          #hpcw_intel_impi_icon = pkgs.confPacks.hpcw_intel_icon.mods;
          #hpcw_intel_impi_ifs_nonemo = pkgs.confPacks.hpcw_intel_impi_ifs_nonemo.mods;
          #hpcw_intel_impi_ifs = pkgs.confPacks.hpcw_intel_impi_ifs.mods;
          #hpcw_intel_impi_ifs-fvm = pkgs.confPacks.hpcw_intel_impi_ifs-fvm.mods; # FIXME ifs-fvm requires to be built on 1 core only
          #hpcw_intel_impi_nemo_small = pkgs.confPacks.hpcw_intel_impi_nemo_small.mods;
          #hpcw_intel_impi_nemo_medium = pkgs.confPacks.hpcw_intel_impi_nemo_medium.mods;

          hpcw_nvhpc_cloudsc = pkgs.confPacks.hpcw_nvhpc_cloudsc.mods;
        });
    }))
    // {
      lib = nixpkgs.lib;

      overlays.default = final: prev:
        with prev; let
          ucx_detect = feature: let
            info = capture [feature] {
              name = "ucx_detect.sh";
              builder = ./ucx_detect.sh;
            };
          in
            builtins.trace info
            (
              if info == "true"
              then true
              else false
            );
        in {
          packs.default = prev.packs'.default._merge (self:
            with self; {
              os = "nixos22";
              spackConfig.config.source_cache = "/tmp/spack/mirror";
              spackPython = "${python3}/bin/python3";
              spackShell = "${bash}/bin/bash";
              spackEnv = {
                # pure environment PATH
                PATH =
                  /*
                              "/run/current-system/sw/bin:"
                  +
                  */
                  inputs.nixpkgs.lib.concatStringsSep ":"
                  (builtins.map (x: "${x}/bin")
                    [
                      bash
                      curl
                      coreutils
                      gnumake
                      gnutar
                      gzip
                      bzip2
                      xz
                      gawk
                      gnused
                      gnugrep
                      glib
                      binutils.bintools # glib: locale
                      patch
                      texinfo
                      diffutils
                      pkgconfig
                      gitMinimal
                      findutils
                    ])
                  + "/bin"
                  + "/usr/bin"
                  + "/usr/sbin";
                #PATH="/run/current-system/sw/bin:${pkgs.gnumake}/bin:${pkgs.binutils.bintools}/bin";
                LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
                LIBRARY_PATH =
                  /*
                                      "/run/current-system/sw/bin:"
                  +
                  */
                  inputs.nixpkgs.lib.concatStringsSep ":"
                  (builtins.map (x: "${x}/lib")
                    [
                      (inputs.nixpkgs.lib.getLib binutils.bintools) # ucx (configure fails) libbfd not found
                    ]);
              };

              package = {
                compiler = let
                  gccWithFortran = wrapCC (gcc.cc.override {
                    langFortran = true;
                  });
                in {
                  name = "gcc";
                  extern = gccWithFortran;
                  version = gccWithFortran.version;
                };
                perl = {
                  extern = perl;
                  version = perl.version;
                };
                openssh = {
                  extern = openssh;
                  version = openssh.version;
                };
                openssl = {
                  extern = symlinkJoin {
                    name = "openssl";
                    paths = [openssl.all];
                  };
                  version = openssl.version;
                };
                openmpi = {
                  version = "4.1";
                  variants = {
                    fabrics = {
                      none = false;
                      ucx = true;
                    };
                    schedulers = {
                      none = false;
                      slurm = false;
                    };
                    pmix = false;
                    static = false;
                    legacylaunchers = true;
                  };
                };
              };
            });
        };
    };
}
