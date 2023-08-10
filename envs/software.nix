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
      gcc10_compiler.pack = pkgs.confPacks.gcc10_compiler;
      gcc11_compiler.pack = pkgs.confPacks.gcc11_compiler;
      gcc12_compiler.pack = pkgs.confPacks.gcc12_compiler;
      gcc13_compiler.pack = pkgs.confPacks.gcc13_compiler;
      aocc41_compiler.pack = pkgs.confPacks.aocc41_compiler;
      aocc40_compiler.pack = pkgs.confPacks.aocc40_compiler;
      aocc32_compiler.pack = pkgs.confPacks.aocc32_compiler;
      llvm16_compiler.pack = pkgs.confPacks.llvm16_compiler;

      gcc13_osu.pack = pkgs.confPacks.gcc13_osu;
      gcc13_ompi_osu.pack = pkgs.confPacks.gcc13_ompi_osu;
      intel_ompi_osu.pack = pkgs.confPacks.intel_ompi_osu;
      intel_impi_osu.pack = pkgs.confPacks.intel_impi_osu;
    };
  };
}
