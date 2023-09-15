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
      ai4sim_gcc12.pack = pkgs.confPacks.ai4sim_gcc12;
    };
  };
}
