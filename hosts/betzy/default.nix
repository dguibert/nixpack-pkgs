{
  packs',
  rpmExtern,
  python3,
}:
packs'.default._merge (self:
    with self; {
      os = "rhel7";
      spackConfig.config.source_cache = "/cluster/projects/nn9560k/dguibert/spack/mirror";
      spackPython = "${python3}/bin/python3";
      spackEnv.PATH = "/bin:/usr/bin:/usr/sbin";
      spackEnv.INTEL_LICENSE_FILE = "/cluster/installations/licenses/intel/license.lic";

      package = {
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
        autoconf = rpmExtern "autoconf";
        automake = rpmExtern "automake";
        bzip2 = rpmExtern "bzip2";
        curl = rpmExtern "curl";
        diffutils = rpmExtern "diffutils";
        libtool = rpmExtern "libtool";
        m4 = rpmExtern "m4";
        openssh = rpmExtern "openssh";
        openssl = rpmExtern "openssl";
        pkgconfig = rpmExtern "pkgconfig";
        #perl = { extern=pkgs.perl; version=pkgs.perl.version; };
        perl = rpmExtern "perl"; # https://github.com/spack/spack/issues/19144
        slurm =
          rpmExtern "slurm"
          // {
            variants = {
              #pmix = true;
              hwloc = true;
            };
          };
      };
    })
