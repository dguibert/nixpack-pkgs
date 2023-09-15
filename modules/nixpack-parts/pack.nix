{
  config,
  lib,
  options,
  nixpack,
  ...
}: let
  l = lib // builtins;
  t = l.types;
in {
  options = {
    system = l.mkOption {
      default = builtins.currentSystem;
      type = t.string;
    };
    os = l.mkOption {
      default = "unkown";
      type = t.str;
    };
    label = l.mkOption {
      default = "packs";
      type =
        t.str
        // {
          merge = loc: defs: l.concatMapStringsSep "." (getValues defs);
        };
    };
    spackConfig = l.mkOption {
      default = {};
      type = t.raw;
    };
    spackPython = l.mkOption {
      default = "/usr/bin/python3";
      type = t.str;
    };
    spackShell = l.mkOption {
      default = "/bin/bash";
      type = t.str;
    };
    spackEnv = l.mkOption {
      default = {PATH = "/bin:/usr/bin";};
      type = t.raw;
    };
    repos = l.mkOption {
      default = [];
      type = t.raw;
    };
    repoPatch = l.mkOption {
      default = {};
      type = t.raw;
    };
    global = l.mkOption {
      default = {};
      type = t.raw;
    };
    package = l.mkOption {
      default = {};
      type = t.raw;
    };

    packs = mkOption {
      type = t.raw;
      readOnly = true;
    };
  };

  config = {
    packs = nixpack.lib.packs {
      inherit
        (config)
        system
        os
        label
        spackConfig
        spackPython
        spackShell
        spackEnv
        repos
        repoPatch
        global
        package
        ;
    };
  };
}
