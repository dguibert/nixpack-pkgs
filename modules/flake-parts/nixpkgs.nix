{
  inputs,
  perSystem,
  self,
  ...
}: let
  nixpkgsFor = system:
    import (inputs.nixpkgs.inputs.nixpkgs or inputs.nixpkgs) {
      inherit system;
      overlays =
        inputs.nixpkgs.legacyPackages.${system}.overlays
        ++ [
          (final: prev: import ../../overlays/default final (prev // {inherit inputs;}))
          (final: prev: let
            ucx_detect = feature: let
              info = prev.capture [feature] {
                name = "ucx_detect.sh";
                builder = ../../ucx_detect.sh;
              };
            in
              builtins.trace info
              (
                if info == "true"
                then true
                else false
              );
          in
            with prev; {
              packs.default = prev.packs'.default._merge (self:
                with self; {
                  os = "rhel8";
                  spackConfig.config.database_root = "$tempdir"; # for database_directory
                  spackConfig.config.source_cache = "/software/spack/mirror";
                  #spackConfig.config.source_cache = "/dev/shm/spack/mirror";
                  spackConfig.mirrors.software = "/software/spack/mirror";
                  spackPython = "${python3}/bin/python3";
                  spackEnv.PATH = "/bin:/usr/bin:/usr/sbin";
                  #spackEnv.PROXYCHAINS_CONF_FILE = "/dev/shm/proxychains.conf";
                  #spackEnv.LD_PRELOAD = "/dev/shm/libproxychains4.so";
                  #spackEnv.all_proxy = "socks4a://127.0.0.1:33129";
                  spackEnv.http_proxy = "http://10.11.0.1:33000";
                  spackEnv.https_proxy = "http://10.11.0.1:33000";
                  spackEnv.HPCW_DOWNLOAD_URL = "/home_nfs/bguibertd/work/hpcw/downloads";
                  spackEnv.HPCW_URL = "/home_nfs/bguibertd/work/hpcw";
                  # fix CURL certificates path
                  #spackEnv.SSL_CERT_DIR="/etc/ssl/certs";
                  #spackEnv.SSL_CERT_FILE="/etc/pki/ca-trust/extracted/pem/email-ca-bundle.pem";
                  #spackEnv.GIT_SSL_CAINFO="/etc/ssl/certs/ca-bundle.crt";
                  #spackEnv.CURL_CA_BUNDLE="/etc/ssl/certs/ca-bundle.crt";
                  #spackEnv.NIX_SSL_CERT_FILE="/etc/pki/tls/certs/ca-bundle.crt";
                  #spackEnv.CARGO_HTTP_CAINFO="/etc/ssl/certs/ca-bundle.crt";
                  # https://stackoverflow.com/questions/50752302/python3-pycache-generating-even-if-pythondontwritebytecode-1
                  #spackEnv.PYTHONDONTWRITEBYTECODE = "1"; # break py-pandas install?
                  #spackEnv.__contentAddressed = true;
                  package = {
                    autoconf = rpmExtern "autoconf";
                    automake = rpmExtern "automake";
                    bzip2 = rpmExtern "bzip2";
                    curl = rpmExtern "curl";
                    diffutils = rpmExtern "diffutils";
                    libssh = rpmExtern "libssh";
                    #libtool = rpmExtern "libtool";
                    m4 = rpmExtern "m4";
                    openssh = rpmExtern "openssh";
                    openssl = rpmExtern "openssl";
                    pkgconfig = rpmExtern "pkgconf";
                    pkgconf = rpmExtern "pkgconf";
                    #perl      = rpmExtern "perl"; # https://github.com/spack/spack/issues/19144
                    slurm =
                      rpmExtern "slurm"
                      // {
                        variants = {
                          #pmix = true;
                          hwloc = true;
                        };
                      };
                    /*
                    must be set to an external compiler capable of building compiler (above)
                    */
                    compiler =
                      {
                        name = "gcc";
                      }
                      // rpmExtern "gcc";

                    ncurses = {
                      version = rpmVersion "ncurses";
                      variants = {
                        termlib = true;
                      };
                    };
                    hcoll = {
                      extern = "/opt/mellanox/hcoll";
                      version = rpmVersion "hcoll";
                    };
                    knem = rec {
                      extern = "/opt/knem-${version}";
                      version = rpmVersion "knem";
                    };
                    xpmem = {
                      extern = "/opt/xpmem";
                      version = rpmVersion "xpmem";
                    };
                    #pmix = rec { extern= "/opt/pmix/${version}"; version = rpmVersion "pmix"; };
                    openmpi.variants = {
                      lustre = true;
                      fabrics.hcoll = true;
                      fabrics.knem = true;
                    };
                    lustre = rpmExtern "lustre-client";

                    #ucx =
                    #  rpmExtern "ucx" # extern and overriden fails libfabric> spack.repo.UnknownPackageError: Package 'spack.pkg.bench.ucx' not found.
                    #  // {
                    #    variants = {
                    #      assertions = ucx_detect "--with-assertions";
                    #      debug = ucx_detect "--enable-debug";
                    #      logging = ucx_detect "--enable-logging";
                    #      thread_multiple = ucx_detect "ENABLE_MT\\s\\+1";
                    #      optimisations = ucx_detect "--enable-optimizations";
                    #      parameter_checking = ucx_detect "--enable-params-check";
                    #      verbs = ucx_detect "--with-verbs";
                    #      #cm = ucx_detect "--with-cm";
                    #      cma = ucx_detect ":cma";
                    #      xpmem = ucx_detect ":xpmem";
                    #      rc = ucx_detect "HAVE_TL_RC\\s\\+1";
                    #      dc = ucx_detect "HAVE_TL_DC\\s\\+1";
                    #      ud = ucx_detect "HAVE_TL_UD\\s\\+1";
                    #      mlx5-dv = ucx_detect "HAVE_INFINIBAND_MLX5DV_H\\s\\+1";
                    #      ib-hw-tm = ucx_detect "IBV_HW_TM\\s\\+1";
                    #      knem = ucx_detect ":knem";
                    #      cuda = ucx_detect ":cuda";
                    #      gdrcopy = ucx_detect ":gdrcopy";
                    #      rdmacm = ucx_detect ":rdmacm";
                    #      vfs = ucx_detect "--with-fuse3";
                    #      # TODO rocm = true;
                    #    };
                    #  };

                    jube.variants.resource_manager = "slurm";
                  };
                });
            })
        ];
      config = {allowUnfree = true;} // inputs.nixpkgs.legacyPackages.${system}.config;
      #config.contentAddressedByDefault = true;
    };
in {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
    _module.args.pkgs = nixpkgsFor system;

    legacyPackages = nixpkgsFor system;
  };
}
