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
    "${system}" = inputs.flake-utils.lib.flattenTree {
      gcc10_compiler = pkgs.confPacks.gcc10_compiler.mods;
      gcc11_compiler = pkgs.confPacks.gcc11_compiler.mods;
      gcc12_compiler = pkgs.confPacks.gcc12_compiler.mods;
      gcc13_compiler = pkgs.confPacks.gcc13_compiler.mods;
      #aocc41_compiler = pkgs.confPacks.aocc41_compiler.mods;
      aocc40_compiler = pkgs.confPacks.aocc40_compiler.mods;
      aocc32_compiler = pkgs.confPacks.aocc32_compiler.mods;
    };
  });
}
