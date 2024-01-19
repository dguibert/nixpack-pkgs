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

      cbm2-hemocell_gcc13.pack = pkgs.confPacks.cbm2-hemocell_gcc13;

      cbm2-viridian_core.pack = pkgs.confPacks.cbm2-viridian_core;
      cbm2-viridian_core.in-modules-all = false;
      cbm2-viridian_gcc12.pack = pkgs.confPacks.cbm2-viridian_gcc12;
      cbm2-viridian_gcc12.in-modules-all = false;
    };
  };
}
