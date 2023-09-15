{
  config,
  lib,
  options,
  ...
}: let
  l = lib // builtins;
  t = l.types;

  packOpts = [
    ({
      name,
      config,
      ...
    }: {
      options = {
      };
    })
  ];
in {
  options = {
    packs = l.mkOption {
      default = {};
      type = l.attrsOf (t.submodule packOpts);
    };
  };

  config = {
  };
}
