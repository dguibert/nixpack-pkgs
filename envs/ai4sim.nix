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
      ai4sim_gcc11_cuda.pack = pkgs.confPacks.ai4sim_gcc11_cuda;
      ai4sim_gcc11.pack = pkgs.confPacks.ai4sim_gcc11;
      ai4sim_gcc12.pack = pkgs.confPacks.ai4sim_gcc12;
    };
  };
}
