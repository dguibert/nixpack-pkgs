{
  lib,
  flake-parts-lib,
  inputs,
  ...
}: let
  l = lib // builtins;
  t = l.types;
in {
  options.perSystem = flake-parts-lib.mkPerSystemOption ({
    config,
    pkgs,
    inputs',
    self',
    ...
  }: {
    options = {
      envs = l.mkOption {
        type = t.attrsOf (
          t.submoduleWith {
            modules = [
              ({...}: {
                options.pack = l.mkOption {
                  type = t.raw;
                };
                options.in-modules-all = l.mkOption {
                  type = t.bool;
                  default = true;
                };
              })
            ];
            specialArgs = {
            };
          }
        );
        default = {};
        description = "An attribute set of environments";
        example =
          lib.literalExpression ''
          '';
      };
    };

    #config.envs.all =
  });

  config.perSystem = {
    config,
    pkgs,
    ...
  }: let
    generateModules = name: mod_pkgs:
      pkgs.mkModules {
        inherit name;
        pack = pkgs.packs.default.pack;
        withDeps = false;
        # unique does not remove duplicate pkgconf
        pkgs = builtins.filter (x: x.pkg != pkgs.packs.default.pack.pkgs.pkgconf) (l.unique mod_pkgs);
      };
  in {
    /**/
    checks = l.mapAttrs (name: env: env.pack.mods) config.envs;

    devShells = l.mapAttrs (name: env: env.pack.devShell) config.envs;

    packages =
      (l.mapAttrs' (name: env: l.nameValuePair "modules-${name}" (generateModules name (pkgs.findModDeps env.pack.mod_pkgs))) config.envs)
      // {
        "modules-all" = generateModules "all" (
          l.concatMap (n:
            if config.envs.${n}.in-modules-all
            then pkgs.findModDeps config.envs.${n}.pack.mod_pkgs
            else []) (l.attrNames config.envs)
        );
      };
  };
}
