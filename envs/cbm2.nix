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
    };
  };
}
