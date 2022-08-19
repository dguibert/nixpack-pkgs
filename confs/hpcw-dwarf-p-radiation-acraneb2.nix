final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_acraneb2";

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} ${(builtins.parseDrvName self.pack.pkgs.mpi.name).name} cmake dwarf-p-radiation-acraneb2-lonlev-0.91 dwarf-p-radiation-acraneb2-lonlev-0.9";
        };
      mods = final.mkModules label final.pkgs.corePacks mod_pkgs;

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        cmake
        {
          pkg = dwarf-p-acraneb2.withPrefs {
            variants.component = "dwarf-lonlev-0.91";
          };
          projection = "dwarf-p-radiation-acraneb2-lonlev-0.91/{version}";
        }
        {
          pkg = dwarf-p-acraneb2.withPrefs {
            variants.component = "dwarf-lonlev-0.9";
          };
          projection = "dwarf-p-radiation-acraneb2-lonlev-0.9/{version}";
        }
      ];
    })
