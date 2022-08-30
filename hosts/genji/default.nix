{
  packs',
  rpmExtern,
  rpmVersion,
  python3,
  capture,
}: let
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
in
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

      #module
      #MODULES_RUN_QUARANTINE=LD_LIBRARY_PATH LD_PRELOAD
      #MODULEPATH=/opt/mpi/modulefiles:/usr/share/Modules/modulefiles:/etc/modulefiles:/usr/share/modulefiles
      #MODULEPATH_modshare=/opt/mpi/modulefiles:1:/usr/share/Modules/modulefiles:1:/etc/modulefiles:1:/usr/share/modulefiles:1
      #MODULESHOME=/usr/share/Modules
      spackEnv."BASH_FUNC_module%%" = ''        () {  _module_raw "$@" 2>&1
              }'';
      spackEnv."BASH_FUNC__module_raw%%" = ''        () {  unset _mlshdbg;
               if [ "''${MODULES_SILENT_SHELL_DEBUG:-0}" = '1' ]; then
               case "$-" in
               *v*x*)
               set +vx;
               _mlshdbg='vx'
               ;;
               *v*)
               set +v;
               _mlshdbg='v'
               ;;
               *x*)
               set +x;
               _mlshdbg='x'
               ;;
               *)
               _mlshdbg=\'\'
               ;;
               esac;
               fi;
               unset _mlre _mlIFS;
               if [ -n "''${IFS+x}" ]; then
               _mlIFS=$IFS;
               fi;
               IFS=' ';
               for _mlv in ''${MODULES_RUN_QUARANTINE:-};
               do
               if [ "''${_mlv}" = "''${_mlv##*[!A-Za-z0-9_]}" -a "''${_mlv}" = "''${_mlv#[0-9]}" ]; then
               if [ -n "`eval 'echo ''${'$_mlv'+x}'`" ]; then
               _mlre="''${_mlre:-}''${_mlv}_modquar='`eval 'echo ''${'$_mlv'}'`' ";
               fi;
               _mlrv="MODULES_RUNENV_''${_mlv}";
               _mlre="''${_mlre:-}''${_mlv}='`eval 'echo ''${'$_mlrv':-}'`' ";
               fi;
               done;
               if [ -n "''${_mlre:-}" ]; then
               eval `eval ''${_mlre} /usr/bin/tclsh /usr/share/Modules/libexec/modulecmd.tcl bash '"$@"'`;
               else
               eval `/usr/bin/tclsh /usr/share/Modules/libexec/modulecmd.tcl bash "$@"`;
               fi;
               _mlstatus=$?;
               if [ -n "''${_mlIFS+x}" ]; then
               IFS=$_mlIFS;
               else
               unset IFS;
               fi;
               unset _mlre _mlv _mlrv _mlIFS;
               if [ -n "''${_mlshdbg:-}" ]; then
               set -$_mlshdbg;
               fi;
               unset _mlshdbg;
               return $_mlstatus
              }'';
      #BASH_FUNC_switchml%%=() {  typeset swfound=1;
      # if [ "''${MODULES_USE_COMPAT_VERSION:-0}" = '1' ]; then
      # typeset swname='main';
      # if [ -e /usr/share/Modules/libexec/modulecmd.tcl ]; then
      # typeset swfound=0;
      # unset MODULES_USE_COMPAT_VERSION;
      # fi;
      # else
      # typeset swname='compatibility';
      # if [ -e /usr/share/Modules/libexec/modulecmd-compat ]; then
      # typeset swfound=0;
      # MODULES_USE_COMPAT_VERSION=1;
      # export MODULES_USE_COMPAT_VERSION;
      # fi;
      # fi;
      # if [ $swfound -eq 0 ]; then
      # echo "Switching to Modules $swname version";
      # source /usr/share/Modules/init/bash;
      # else
      # echo "Cannot switch to Modules $swname version, command not found";
      # return 1;
      # fi
      #}
      #BASH_FUNC_ml%%=() {  module ml "$@"
      #}
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
      };
    })
