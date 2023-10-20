{
  inputs,
  perSystem,
  ...
}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    ...
  }: {
    envs = {
      cbm2_gcc13.pack = pkgs.confPacks.cbm2_gcc13;

      cbm2-viridian_core.pack = pkgs.confPacks.cbm2-viridian_core;
    };
  };
}
