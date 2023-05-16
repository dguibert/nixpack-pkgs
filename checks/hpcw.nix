{
  inputs,
  withSystem,
  ...
}: {
  flake.checks = withSystem "x86_64-linux" ({
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
    "${system}" =
      rec {
      }
      // (inputs.flake-utils.lib.flattenTree {
        #modules = pkgs.modules;

        hpcw_intel_acraneb2 = pkgs.confPacks.hpcw_intel_acraneb2.mods;
        hpcw_intel_ectrans = pkgs.confPacks.hpcw_intel_ectrans.mods;
        hpcw_intel_ifs = pkgs.confPacks.hpcw_intel_ifs.mods;
        hpcw_intel_ifs_nonemo = pkgs.confPacks.hpcw_intel_ifs_nonemo.mods;
        hpcw_intel_nemo_small = pkgs.confPacks.hpcw_intel_nemo_small.mods;
        hpcw_intel_impi_ecrad = pkgs.confPacks.hpcw_intel_ecrad.mods;
        hpcw_intel_impi_icon = pkgs.confPacks.hpcw_intel_icon.mods;
        hpcw_intel_impi_ifs_nonemo = pkgs.confPacks.hpcw_intel_impi_ifs_nonemo.mods;
        hpcw_intel_impi_ifs = pkgs.confPacks.hpcw_intel_impi_ifs.mods;
        #hpcw_intel_impi_ifs-fvm = pkgs.confPacks.hpcw_intel_impi_ifs-fvm.mods; # FIXME ifs-fvm requires to be built on 1 core only
        hpcw_intel_impi_nemo_small = pkgs.confPacks.hpcw_intel_impi_nemo_small.mods;
        hpcw_intel_impi_nemo_medium = pkgs.confPacks.hpcw_intel_impi_nemo_medium.mods;

        hpcw_nvhpc_cloudsc = pkgs.confPacks.hpcw_nvhpc_cloudsc.mods;
      });
  });
}
