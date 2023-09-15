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
      packs = l.mkOption {
        type = t.lazyAttrsOf (
          t.submoduleWith {
            modules = [
              ../nixpack-parts/pack.nix
            ];
            specialArgs = {
              inherit (inputs) nixpack;
              #inherit (config.nixpack-parts) packageSets;
            };
          }
        );
        default = {};
        description = "An attribute set of packs";
        example = lib.literalExpression ''
          default = {
            package.zlib.version = "1.2";
          };
        '';
      };
    };
  });

  config.perSystem = {
    config,
    pkgs,
    ...
  }: {
    /*
    This exposes the `.packs` attribute (the actual derivation) of each
      defined `packs.xxx` under the flake output `packages`.
    */
    config.packages = l.mapAttrs (name: pkg: pkg.packs) config.packs;
  };
}
