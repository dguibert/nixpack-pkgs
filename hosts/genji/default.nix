{
  packs',
  rpmExtern,
  python3,
}:
packs'.default._merge (self:
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

        ncurses =
          rpmExtern "ncurses"
          // {
            variants = {
              termlib = false;
              abi = "5";
            };
          };
      };
    })
