final:
# default HPCW
pack:
pack._merge (self:
    with self; {
      label = "cbm2_" + pack.label;
      repos = [
        final.cbm_repo
      ];

      package.boost.variants.mpi = true;
      # ctemplate dependency python: package python@3.9.13+bz2+ctypes+dbm~debug+libxml2+lzma~nis~optimizations+pic+pyexpat+pythoncmd+readline+shared+sqlite3+ssl~tix~tkinter~ucs4+uuid+zlib does not match dependency constraints {"version":":2"}
      package.ctemplate.version = "2.4"; # for python @3:
      #hemepure dependency tinyxml: package tinyxml@2.6.2~ipo+shared~stl build_type=RelWithDebInfo does not match dependency constraints {"variants":{"stl":true}}
      package.tinyxml.variants.stl = true;

      # hemocell dependency parmetis: package parmetis@4.0.3~gdb~int64~ipo+shared build_type=RelWithDebInfo does not match dependency constraints {"depends":{"metis":{"variants":{"shared":false}}},"variants":{"shared":false},"version":"4.0.3"}
      package.parmetis.variants.shared = false;
      package.metis.version = "5.1.0";

      package.hemepure.version = "git.15c93cf350424dcd0f2bdc0b6f4ba6876e339b5b=master";
      package.hemepure.variants.inlet_boundary = "NASHZEROTHORDERPRESSUREIOLET";
      package.hemepure.variants.outlet_boundary = "NASHZEROTHORDERPRESSUREIOLET";
      #package.hemepure.variants.wall_boundary = "SIMPLEBOUNCEBACK";
      #package.hemepure.variants.wall_inlet_boundary = "NASHZEROTHORDERPRESSURESBB";
      #package.hemepure.variants.wall_outlet_boundary = "NASHZEROTHORDERPRESSURESBB";
      package.hemepure.variants.wall_boundary = "BFL";
      package.hemepure.variants.wall_inlet_boundary = "NASHZEROTHORDERPRESSUREBFL";
      package.hemepure.variants.wall_outlet_boundary = "NASHZEROTHORDERPRESSUREBFL";

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        cmake
        hemepure
        tinyxml
        parmetis
        boost
        ctemplate
        slms-loadbalancing
        libtirpc
      ];

      dockerImgArgs = {
        config = {
          WorkingDir = "/data";
          Volumes = {
            "/data" = {};
          };
        };
      };
      img_pkgs = with final; with self.pack.pkgs; let
        # https://jarvice.readthedocs.io/en/latest/nae/
        appDef = {
          name = "mpiapp";
          description = "An mpi application";
          author = "Me";
          licensed = false;
          appdefversion = 2;
          classifications = [
            "Uncategorized"
          ];
          machines = [
            "*"
          ];
          vault-types = [
            "FILE"
            "BLOCK"
            "BLOCK_ARRAY"
            "OBJECT"
          ];
          commands = {
            hemepure = {
              path = "${hemepure}/bin/hemepure";
              mpirun = true;
              verboseinit = true;
              interactive = false;
              name = "Hemepure Executable";
              description = "Run the Hemepure Benchmark over multiple nodes.";
              parameters = {};
            };
          };
          image = {
            data = "";
            type = "image/png";
          };
        };
        fakeRhel = pkgs.runCommand "fake-rhel" {} ''
          mkdir -p $out/lib64
          cp /lib64/ld-2.28.so $out/lib64
          cp /lib64/ld-linux-x86-64.so.2 $out/lib64
          cp /lib64/libc-2.28.so $out/lib64
          cp /lib64/libc.so.6 $out/lib64
          cp /lib64/libdl-2.28.so $out/lib64
          cp /lib64/libdl.so.2 $out/lib64
          cp /lib64/libkeyutils.so.1 $out/lib64
          cp /lib64/libkeyutils.so.1.6 $out/lib64
          cp /lib64/libm-2.28.so $out/lib64
          cp /lib64/libm.so.6 $out/lib64
          cp /lib64/libpthread-2.28.so $out/lib64
          cp /lib64/libpthread.so.0 $out/lib64
          cp /lib64/libresolv-2.28.so $out/lib64
          cp /lib64/libresolv.so.2 $out/lib64
          cp /lib64/librt-2.28.so $out/lib64
          cp /lib64/librt.so.1 $out/lib64
          cp /lib64/libutil-2.28.so $out/lib64
          cp /lib64/libutil.so.1 $out/lib64
          cp /lib64/libcrypto.so.1.1 $out/lib64
          cp /lib64/libz.so.1 $out/lib64
          cp /lib64/libcrypt.so.1 $out/lib64
          cp /lib64/libselinux.so.1 $out/lib64
          cp /lib64/libgssapi_krb5.so.2 $out/lib64
          cp /lib64/libkrb5.so.3 $out/lib64
          cp /lib64/libk5crypto.so.3 $out/lib64
          cp /lib64/libcom_err.so.2 $out/lib64
          cp /lib64/libpcre2-8.so.0 $out/lib64
          cp /lib64/libkrb5support.so.0 $out/lib64
          cp /lib64/libkeyutils.so.1 $out/lib64

          # Lustre
          cp /lib64/liblustreapi.so.1 $out/lib64

          # Ucx
          mkdir -p $out/usr/bin $out/lib64
          cp /usr/bin/io_demo $out/usr/bin
          cp /usr/bin/ucx_info $out/usr/bin
          cp /usr/bin/ucx_perftest $out/usr/bin
          cp /usr/bin/ucx_read_profile $out/usr/bin
          cp /usr/lib64/libucm.so.0 $out/lib64
          cp /usr/lib64/libucm.so.0.0.0 $out/lib64
          cp /usr/lib64/libucp.so.0 $out/lib64
          cp /usr/lib64/libucp.so.0.0.0 $out/lib64
          cp /usr/lib64/libucs.so.0 $out/lib64
          cp /usr/lib64/libucs.so.0.0.0 $out/lib64
          cp /usr/lib64/libucs_signal.so.0 $out/lib64
          cp /usr/lib64/libucs_signal.so.0.0.0 $out/lib64
          cp /usr/lib64/libuct.so.0 $out/lib64
          cp /usr/lib64/libuct.so.0.0.0 $out/lib64

          # HColl
          mkdir -p $out/opt/mellanox
          cp -R /opt/mellanox/hcoll $out/opt/mellanox

          mkdir $out/bin
          cp /usr/bin/ldd $out/bin/ldd
          cp /usr/bin/ssh $out/bin/ssh
        '';
        in [
        mpi
        hemepure
        bashInteractive
        final.coreutils
        fakeNss
        (writeTextDir "etc/NAE/AppDef.json" (builtins.toJSON appDef))
        fakeRhel
      ];
    })
