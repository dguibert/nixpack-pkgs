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

      # fails
      #ai4sim_torchfort_gcc11.pack = pkgs.confPacks.ai4sim_torchfort_gcc11;
      #ai4sim_torchfort_gcc11.in-modules-all = false;
      #ai4sim_torchfort_nvhpc235.pack = pkgs.confPacks.ai4sim_torchfort_nvhpc235;
    };
  };
}
