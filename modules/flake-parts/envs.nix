{
  lib,
  flake-parts-lib,
  inputs,
  ...
}: let
  l = lib // builtins;
  t = l.types;

  gitrev = "${lib.substring 0 8 (inputs.self.lastModifiedDate or inputs.self.lastModified or "19700101")}.${inputs.self.shortRev or inputs.self.dirtyShortRev}";
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
        # unique does not remove duplicate pkgconf/curl
        pkgs =
          builtins.filter (x: (x.pkg or x) != pkgs.packs.default.pack.pkgs.pkgconf)
          (builtins.filter (x: (x.pkg.spec.name or "notdef") != "curl")
            (builtins.filter (x: (x.pkg.spec.name or "notdef") != "pkgconf")
              (l.unique mod_pkgs)));
      };
  in {
    /**/
    checks = l.mapAttrs (name: env: env.pack.mods) config.envs;

    devShells = l.mapAttrs (name: env: env.pack.devShell) config.envs;

    packages =
      (l.mapAttrs' (name: env: l.nameValuePair "modules-${name}" (generateModules name (pkgs.findModDeps env.pack.mod_pkgs))) config.envs)
      // rec {
        "modules-all" = generateModules "all" (
          l.concatMap (n:
            if config.envs.${n}.in-modules-all
            then pkgs.findModDeps config.envs.${n}.pack.mod_pkgs
            else []) (l.attrNames config.envs)
        );

        modsMod = import ../../overlays/default/lmod/modules.nix gitrev pkgs.packs.default.pack modules-all;
      };
  };
}
