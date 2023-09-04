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
    fromImage = ubi8;
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
  basic_image = pkgs.dockerTools.buildImage {
    name = "basic-image";
    tag = "latest";
    #fakeRootCommands = ''
    #  mkdir -p ./home/nimbix/.ssh
    #  chown 505:505 -P ./home/nimbix/.ssh
    #'';
    copyToRoot = [
      # should be last layer
      (writeTextDir "etc/NAE/AppDef.json" (builtins.toJSON appDef))
      dockerTools.binSh
      dockerTools.usrBinEnv
      bashInteractive
      coreutils
      sudo
      pam
      su
      strace
      (fakeNss.override {
        extraPasswdLines = [
          "nimbix:x:505:505:Nimbix user:/home/nimbix:/bin/bash"
        ];
        extraGroupLines = [
          "nimbix:!:505:"
        ];
      })
      (writeTextDir "etc/shadow" ''
        root:!:19094::::::
        nimbix:$y$j9T$HqIvPhkUMjaJIflbF/Ozp1$TuOSm8QQBXgQdEl0gGle5xB7WoB1mNBKXjmnW3OEc2D:1::::::
      '')
      (writeTextDir "etc/pam.d/su" ''
        # Account management.
        account required pam_unix.so

        # Authentication management.
        auth sufficient pam_rootok.so
        auth required pam_faillock.so
        auth sufficient pam_unix.so   likeauth try_first_pass
        auth required pam_deny.so

        # Password management.
        password sufficient pam_unix.so nullok yescrypt

        # Session management.
        session required pam_env.so conffile=/etc/pam/environment readenv=0
        session required pam_unix.so
      '')
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
      (writeTextDir "etc/sudoers.d/nimbix.conf" ''
        # "root" is allowed to do anything.
        root        ALL=(ALL:ALL) SETENV: ALL
        Defaults: nimbix !requiretty
        Defaults: root !requiretty
        nimbix ALL=(ALL) NOPASSWD: ALL
      '')
      shadow
    ];
  };
in {
  inherit
    basic_image
    basic_ubi8_image
    jarvice_mpi_image
    ubi8_image
    ;
}
