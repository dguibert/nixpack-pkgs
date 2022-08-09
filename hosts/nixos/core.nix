{
  pkgs,
  inputs,
  ...
}: let
  gccWithFortran = pkgs.wrapCC (pkgs.gcc.cc.override {
    langFortran = true;
  });
in {
  os = "nixos22";
  spackConfig.config.source_cache = "/tmp/spack/mirror";
  spackPython = "${pkgs.python3}/bin/python3";
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
          pkgs.bash
          pkgs.curl
          pkgs.coreutils
          pkgs.gnumake
          pkgs.gnutar
          pkgs.gzip
          pkgs.bzip2
          pkgs.xz
          pkgs.gawk
          pkgs.gnused
          pkgs.gnugrep
          pkgs.glib
          pkgs.binutils.bintools # glib: locale
          pkgs.patch
          pkgs.texinfo
          pkgs.diffutils
          pkgs.pkgconfig
          pkgs.gitMinimal
          pkgs.findutils
        ]);
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
          (inputs.nixpkgs.lib.getLib pkgs.binutils.bintools) # ucx (configure fails) libbfd not found
        ]);
  };

  package = {
    compiler = {
      name = "gcc";
      extern = gccWithFortran;
      version = gccWithFortran.version;
    };
    perl = {
      extern = pkgs.perl;
      version = pkgs.perl.version;
    };
    openssh = {
      extern = pkgs.openssh;
      version = pkgs.openssh.version;
    };
    openssl = {
      extern = pkgs.symlinkJoin {
        name = "openssl";
        paths = [pkgs.openssl.all];
      };
      version = pkgs.openssl.version;
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
        pmi = false;
        pmix = false;
        static = false;
        legacylaunchers = true;
      };
    };
  };
}
