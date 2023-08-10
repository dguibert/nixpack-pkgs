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
      hpcw_intel_acraneb2.pack = pkgs.confPacks.hpcw_intel_acraneb2;
      hpcw_intel_ectrans.pack = pkgs.confPacks.hpcw_intel_ectrans;
      hpcw_intel_ifs.pack = pkgs.confPacks.hpcw_intel_ifs;
      hpcw_intel_ifs_nonemo.pack = pkgs.confPacks.hpcw_intel_ifs_nonemo;
      hpcw_intel_nemo_small.pack = pkgs.confPacks.hpcw_intel_nemo_small;
      hpcw_intel_impi_ecrad.pack = pkgs.confPacks.hpcw_intel_ecrad;
      hpcw_intel_impi_icon.pack = pkgs.confPacks.hpcw_intel_icon;
      hpcw_intel_impi_ifs_nonemo.pack = pkgs.confPacks.hpcw_intel_impi_ifs_nonemo;
      hpcw_intel_impi_ifs.pack = pkgs.confPacks.hpcw_intel_impi_ifs;
      hpcw_intel_impi_ifs-fvm.pack = pkgs.confPacks.hpcw_intel_impi_ifs-fvm; # FIXME ifs-fvm requires to be built on 1 core only
      hpcw_intel_impi_nemo_small.pack = pkgs.confPacks.hpcw_intel_impi_nemo_small;
      hpcw_intel_impi_nemo_medium.pack = pkgs.confPacks.hpcw_intel_impi_nemo_medium;

      hpcw_nvhpc_cloudsc.pack = pkgs.confPacks.hpcw_nvhpc_cloudsc;
      hpcw_nvhpc_cloudsc.in-modules-all = false;
    };
  };
}
