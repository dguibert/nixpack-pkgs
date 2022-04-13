{ rpmExtern
, pkgs
, ...
}: {
  os = "rhel7";
  spackConfig.config.source_cache="/cluster/projects/nn9560k/dguibert/spack/mirror";
  spackPython = "${pkgs.python3}/bin/python3";
  spackEnv.PATH = "/bin:/usr/bin:/usr/sbin";

  package = {
    autoconf  = rpmExtern "autoconf";
    automake  = rpmExtern "automake";
    bzip2     = rpmExtern "bzip2";
    curl      = rpmExtern "curl";
    diffutils = rpmExtern "diffutils";
    libtool   = rpmExtern "libtool";
    m4        = rpmExtern "m4";
    openssh   = rpmExtern "openssh";
    openssl   = rpmExtern "openssl";
    pkgconfig = rpmExtern "pkgconfig";
    #perl      = rpmExtern "perl"; # https://github.com/spack/spack/issues/19144
    slurm     = rpmExtern "slurm" // {
        variants = {
        #pmix = true;
        hwloc = true;
      };
    };
  };
}
