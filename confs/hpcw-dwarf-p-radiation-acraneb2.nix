final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_acraneb2";

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
