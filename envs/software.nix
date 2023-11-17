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
      core_tools.pack = pkgs.confPacks.core_tools;

      gcc10_compiler.pack = pkgs.confPacks.gcc10_compiler;
      gcc11_compiler.pack = pkgs.confPacks.gcc11_compiler;
      gcc12_compiler.pack = pkgs.confPacks.gcc12_compiler;
      gcc13_compiler.pack = pkgs.confPacks.gcc13_compiler;
      aocc41_compiler.pack = pkgs.confPacks.aocc41_compiler;
      aocc40_compiler.pack = pkgs.confPacks.aocc40_compiler;
      aocc32_compiler.pack = pkgs.confPacks.aocc32_compiler;
      llvm16_compiler.pack = pkgs.confPacks.llvm16_compiler;
      llvm17_compiler.pack = pkgs.confPacks.llvm17_compiler;
      nvhpc237_compiler.pack = pkgs.confPacks.nvhpc237_compiler;
      nvhpc_compiler.pack = pkgs.confPacks.nvhpc_compiler;
      intel-oneapi_compiler.pack = pkgs.confPacks.intel-oneapi_compiler;
      intel-oneapi202400_compiler.pack = pkgs.confPacks.intel-oneapi202400_compiler;
      intel-oneapi2024_compiler.pack = pkgs.confPacks.intel-oneapi2024_compiler;

      gcc13_osu.pack = pkgs.confPacks.gcc13_osu;
      gcc13_ompi_osu.pack = pkgs.confPacks.gcc13_ompi_osu;
      intel_ompi_osu.pack = pkgs.confPacks.intel_ompi_osu;
      intel_impi_osu.pack = pkgs.confPacks.intel_impi_osu;

      hip55_core.pack = pkgs.confPacks.hip55_core;
      hip56_core.pack = pkgs.confPacks.hip56_core;
      hip57_core.pack = pkgs.confPacks.hip57_core;
    };
  };
}
