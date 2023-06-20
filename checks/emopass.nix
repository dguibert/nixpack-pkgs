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
      emopass_intel = pkgs.confPacks.emopass_intel.mods;
    };
  });
}
