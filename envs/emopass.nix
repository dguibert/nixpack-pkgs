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
      emopass_intel.pack = pkgs.confPacks.emopass_intel;
    };
  };
}
