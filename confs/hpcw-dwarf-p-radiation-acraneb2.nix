final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_acraneb2";

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${package.compiler.name} cmake";
        };

      mods = with final.pkgs;
        mkModules corePacks (with self.pack.pkgs; [
          compiler
          cmake
        ]);
    })
