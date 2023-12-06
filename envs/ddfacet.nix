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
      ddfacet_gcc13_ompi.pack = pkgs.confPacks.ddfacet_gcc13_ompi;
      #ddfacet_gcc13_ompi.in-modules-all = false; # libx11 -> libxcb -> python
      ddfacet_exp_gcc13_ompi.pack = pkgs.confPacks.ddfacet_exp_gcc13_ompi;

      python_gcc13_ompi.pack = pkgs.confPacks.python_gcc13_ompi;
    };
  };
}
