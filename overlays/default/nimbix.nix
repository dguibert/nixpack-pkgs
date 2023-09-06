final: prev:
with prev; let
  jarvice_mpi_image = pkgs.dockerTools.pullImage {
    #us-docker.pkg.dev/jarvice/images/jarvice_mpi:4.1 ->
    # https://console.cloud.google.com/artifacts/docker/jarvice/us/images/jarvice_mpi/sha256:809f811318ac705018763cbbe0dff88b57e9e44a206033f8224310ec46aa9bd4
    imageName = "us-docker.pkg.dev/jarvice/images/jarvice_mpi";
    imageDigest = "sha256:809f811318ac705018763cbbe0dff88b57e9e44a206033f8224310ec46aa9bd4";
    sha256 = "sha256-1FtPswQttAF6qJFscDNmKG+G9/LvtqGvV0rYrXXvqBI=";
    finalImageTag = "4.1";
    finalImageName = "jarvice_mpi";
  };

  ubi8_image = pkgs.dockerTools.pullImage {
    imageName = "redhat/ubi8"; #:8.8-854
    imageDigest = "sha256:0a342233b8a501dc2e46b943ad75bedb396ff6bc27dfc02665fd2014ebd87f8d";
    sha256 = "sha256-rmXNBdVglXFv43NplCMqsKfRSLf+JUtvzBAon/Vs3WQ=";
    finalImageTag = "8.8-854";
    finalImageName = "ubi8";
  };

  alpine_image = pkgs.dockerTools.pullImage {
    imageName = "alpine"; #:8.8-854
    imageDigest = "sha256:c5c5fda71656f28e49ac9c5416b3643eaa6a108a8093151d6d1afc9463be8e33";
    sha256 = "sha256-3K73rB1MoF/co3J61jvGPacxClxswsNAdQ2wDvlZLIs=";
    finalImageTag = "3.18.3";
    finalImageName = "alpine";
  };

  appDef = {
    name = "basic";
    description = "Basic image";
    author = "dguibert";
    licensed = false;
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
      hello = {
        path = "/bin/echo";
        verboseinit = true;
        webshell = false;
        interactive = false;
        name = "say hello";
        description = "Hello world";
        parameters = {
          hello = {
            name = "hello";
            description = "hello";
            type = "CONST";
            value = "Hello World";
            positional = true;
            required = true;
          };
        };
      };
      bash = {
        path = "/bin/bash";
        verboseinit = true;
        webshell = false;
        interactive = true;
        name = "bash";
        description = "Interactive Bash";
        parameters = {};
      };
    };
    image = {
      data = "";
      type = "image/png";
    };
  };
  basic_ubi8_image = pkgs.dockerTools.buildImage {
    name = "ubi8-image";
    tag = "latest";
    #fakeRootCommands = ''
    #  mkdir -p ./home/nimbix/.ssh
    #  chown 505:505 ./home/nimbix
    #'';
    fromImage = ubi8_image;
    copyToRoot = [
      #dockerTools.binSh
      #dockerTools.usrBinEnv
      #bashInteractive
      #coreutils
      #sudo
      #pam
      #su
      #strace
      #(fakeNss.override {
      #  extraPasswdLines = [
      #    "nimbix:x:505:505:Nimbix user:/home/nimbix:/bin/bash"
      #  ];
      #  extraGroupLines = [
      #    "nimbix:!:505:"
      #  ];
      #})
      #(writeTextDir "etc/shadow" ''
      #  root:!:19094::::::
      #  nimbix:$y$j9T$HqIvPhkUMjaJIflbF/Ozp1$TuOSm8QQBXgQdEl0gGle5xB7WoB1mNBKXjmnW3OEc2D:1::::::
      #'')
      #(writeTextDir "etc/pam.d/su" ''
      #  # Account management.
      #  account required pam_unix.so
      #
      #  # Authentication management.
      #  auth sufficient pam_rootok.so
      #  auth required pam_faillock.so
      #  auth sufficient pam_unix.so   likeauth try_first_pass
      #  auth required pam_deny.so
      #
      #  # Password management.
      #  password sufficient pam_unix.so nullok yescrypt
      #
      #  # Session management.
      #  session required pam_env.so conffile=/etc/pam/environment readenv=0
      #  session required pam_unix.so
      #'')
      #(writeTextDir "etc/pam.d/sudo" ''
      #  # Account management.
      #  account required pam_unix.so
      #
      #  # Authentication management.
      #  auth sufficient pam_unix.so   likeauth try_first_pass
      #  auth required pam_deny.so
      #
      #  # Password management.
      #  password sufficient pam_unix.so nullok yescrypt
      #
      #  # Session management.
      #  session required pam_env.so conffile=/etc/pam/environment readenv=0
      #  session required pam_unix.so
      #'')
      #(writeTextDir "etc/sudoers.d/nimbix.conf" ''
      #  # "root" is allowed to do anything.
      #  root        ALL=(ALL:ALL) SETENV: ALL
      #  Defaults: nimbix !requiretty
      #  Defaults: root !requiretty
      #  nimbix ALL=(ALL) NOPASSWD: ALL
      #'')
      # should be last layer
      (writeTextDir "etc/NAE/AppDef.json" (builtins.toJSON appDef))
    ];
  };
  basic_alpine_image = pkgs.dockerTools.buildLayeredImage {
    name = "basic-image";
    tag = "latest";
    fromImage = alpine_image;
    fakeRootCommands = ''
      mkdir -p ./home/nimbix/.ssh
      chown 505:505 -P ./home/nimbix/.ssh
    '';
    contents = [
      # should be last layer
      (writeTextDir "etc/NAE/AppDef.json" (builtins.toJSON appDef))
      (fakeNss.override {
        extraPasswdLines = [
          "nimbix:x:505:505:Nimbix user:/home/nimbix:/bin/bash"
        ];
        extraGroupLines = [
          "nimbix:!:505:"
        ];
      })
    ];
  };

  nimbixImage = {
    name ? "nimbix-image",
    tag ? "latest",
    contents ? [],
    ...
  } @ args: let
    fakeNss = final.fakeNss.override {
      extraPasswdLines = [
        "nimbix:x:505:505:Nimbix user:/home/nimbix:/bin/bash"
      ];
      extraGroupLines = [
        "nimbix:!:505:"
      ];
    };
  in
    pkgs.dockerTools.buildLayeredImage ({
        inherit name tag;
        fakeRootCommands =
          ''
            mkdir ./usr
            ln -s /bin ./usr/bin
            ln -s /sbin ./usr/sbin

            # hack (?)
            rm ./bin/passwd
            cp -v ${shadow}/bin/passwd ./bin/
            chmod +s ./bin/passwd

            # /bin/sudo must be owned by uid 0 and have the setuid bit set
            rm ./bin/sudo
            cp -v ${sudo}/bin/sudo ./bin/
            chmod +s ./bin/sudo

            mkdir -p ./etc
            cat > ./etc/shadow <<EOF
            root:!:19094::::::
            nimbix:$y$j9T$HqIvPhkUMjaJIflbF/Ozp1$TuOSm8QQBXgQdEl0gGle5xB7WoB1mNBKXjmnW3OEc2D:1::::::
            EOF
            rm -f ./etc/passwd ./etc/group
            cp -vL ${fakeNss}/etc/passwd ./etc/passwd
            cp -vL ${fakeNss}/etc/group ./etc/group

            mkdir -p ./home/nimbix/.ssh
            chown 505:505 -P ./home/nimbix/.ssh
          ''
          + (args.fakeRootCommands or "");
        contents =
          [
            # should be last layer
            (writeTextDir "etc/NAE/AppDef.json" (builtins.toJSON appDef))
            dockerTools.binSh
            #dockerTools.usrBinEnv
            bashInteractive
            coreutils
            sudo
            pam
            su
            strace
            (writeTextDir "etc/pam.d/sudo" ''
              # Account management.
              account required pam_unix.so

              # Authentication management.
              auth sufficient pam_unix.so   likeauth try_first_pass
              auth required pam_deny.so

              # Password management.
              password sufficient pam_unix.so nullok yescrypt

              # Session management.
              session required pam_env.so conffile=/etc/pam/environment readenv=0
              session required pam_unix.so
            '')
            (writeTextDir "etc/pam.d/system-auth" ''
              # Account management.
              account required pam_unix.so

              # Authentication management.
              auth sufficient pam_unix.so   likeauth try_first_pass
              auth required pam_deny.so

              # Password management.
              password sufficient pam_unix.so nullok yescrypt

              # Session management.
              session required pam_env.so conffile=/etc/pam/environment readenv=0
              session required pam_unix.so
            '')
            (writeTextDir "etc/sudoers.d/nimbix.conf" ''
              # "root" is allowed to do anything.
              root        ALL=(ALL:ALL) SETENV: ALL
              Defaults: nimbix !requiretty
              Defaults: root !requiretty
              nimbix ALL=(ALL) NOPASSWD: ALL
            '')
            shadow
          ]
          ++ args.contents;
      }
      // (builtins.removeAttrs args ["name" "tag" "contents" "fakeRootCommands"]));

  basic_image = nimbixImage {
    name = "basic-image";
    contents = [];
  };
in {
  inherit
    nimbixImage
    alpine_image
    basic_image
    basic_alpine_image
    basic_ubi8_image
    jarvice_mpi_image
    ubi8_image
    ;
}
