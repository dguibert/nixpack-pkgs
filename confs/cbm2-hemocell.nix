final:
# default HPCW
pack:
pack._merge (self:
    with self; {
      label = "cbm2-hemocell_" + pack.label;

      package.hemocell.version = "git.2546b20555ede99c496423c0db0b6bac17579752=export_cube";
      package.hemocell.variants.parmetis = false;
      package.parmetis.version = "4.0.3";
      package.parmetis.variants.shared = false;
      package.metis.variants.shared = false;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        hemocell
      ];
    })
