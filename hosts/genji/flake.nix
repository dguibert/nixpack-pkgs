{
  description = "A flake for building my NIXPACK packages on GENJI";

  inputs.upstream.url = "path:../..";
  inputs.nixpkgs.follows = "upstream/nixpkgs";
  inputs.flake-utils.follows = "upstream/flake-utils";

  outputs = { self, nixpkgs, flake-utils, upstream, ... }: let
    nixpkgsFor = system:
      import upstream.inputs.nixpkgs.inputs.nixpkgs {
        inherit system;
        overlays =  upstream.legacyPackages.${system}.overlays ++ [
          self.overlays.default
        ];
        config = upstream.legacyPackages.${system}.config;
    };
  in (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {
    legacyPackages = nixpkgsFor system;
  })) // {
    lib = nixpkgs.lib;

    overlays.default = final: prev: with prev;
      let
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
            os = "rhel8";
            spackConfig.config.source_cache = "/software/spack/mirror";
            #spackConfig.config.source_cache="/dev/shm/spack/mirror";
            spackConfig.mirrors.software = "/software/spack/mirror";
            spackPython = "${python3}/bin/python3";
            #spackPython = if system == "x86_64-linux"  then "/home_nfs/bguibertd/.home-x86_64/.nix-profile/bin/python3"
            #         else if system == "aarch64-linux" then "/home_nfs/bguibertd/.home-aarch64/.nix-profile/bin/python3"
            #         else throw "python not already installed for system: ${system}";
            spackEnv.PATH = "/bin:/usr/bin:/usr/sbin";
            spackEnv.PROXYCHAINS_CONF_FILE = "/dev/shm/proxychains.conf";
            spackEnv.LD_PRELOAD = "/dev/shm/libproxychains4.so";
            spackEnv.HPCW_DOWNLOAD_URL = "/home_nfs/bguibertd/work/hpcw/downloads";
            spackEnv.__contentAddressed = true;
            ## only fixedCA drvs allow impureEnvVars
            #spackEnv.impureEnvVars = [
            #  "http_proxy" "https_proxy"
            #  "PROXYCHAINS_CONF_FILE" "LD_PRELOAD"
            #];
            package = {
              autoconf = rpmExtern "autoconf";
              automake = rpmExtern "automake";
              bzip2 = rpmExtern "bzip2";
              curl = rpmExtern "curl";
              diffutils = rpmExtern "diffutils";
              libtool = rpmExtern "libtool";
              m4 = rpmExtern "m4";
              openssh = rpmExtern "openssh";
              openssl = rpmExtern "openssl";
              pkgconf = rpmExtern "pkgconf";
              pkgconfig = rpmExtern "pkgconf";
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
              ucx =
                rpmExtern "ucx"
                // {
                  variants = {
                    assertions = ucx_detect "--with-assertions";
                    debug = ucx_detect "--enable-debug";
                    logging = ucx_detect "--enable-logging";
                    thread_multiple = ucx_detect "ENABLE_MT\\s\\+1";
                    optimisations = ucx_detect "--enable-optimizations";
                    parameter_checking = ucx_detect "--enable-params-check";
                    verbs = ucx_detect "--with-verbs";
                    #cm = ucx_detect "--with-cm";
                    cma = ucx_detect ":cma";
                    xpmem = ucx_detect ":xpmem";
                    rc = ucx_detect "HAVE_TL_RC\\s\\+1";
                    dc = ucx_detect "HAVE_TL_DC\\s\\+1";
                    ud = ucx_detect "HAVE_TL_UD\\s\\+1";
                    mlx5-dv = ucx_detect "HAVE_INFINIBAND_MLX5DV_H\\s\\+1";
                    ib-hw-tm = ucx_detect "IBV_HW_TM\\s\\+1";
                    knem = ucx_detect ":knem";
                    cuda = ucx_detect ":cuda";
                    gdrcopy = ucx_detect ":gdrcopy";
                    rdmacm = ucx_detect ":rdmacm";
                    vfs = ucx_detect "--with-fuse3";
                    # TODO rocm = true;
                  };
                };

              jube.variants.resource_manager = "slurm";
            };
          });
    };
  };
}
