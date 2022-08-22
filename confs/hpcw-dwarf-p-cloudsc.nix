final: pack:
pack._merge (self:
    with self; {
      label = "hpcw_" + pack.label + "_cloudsc";

      package.dwarf-p-cloudsc.variants.gpu = true;
      package.dwarf-p-cloudsc.variants.cloudsc-gpu-claw = true;
      #package.dwarf-p-cloudsc.variants.hdf5 = false;
      #package.dwarf-p-cloudsc.variants.serialbox = true;
      package.dwarf-p-cloudsc.variants.cloudsc-c = false; # require serialbox?
      package.serialbox.version = "2.5.4-patched"; # require private url (TODO implement curl -n)

      devShell = with final.pkgs;
        mkDevShell {
          name = label;
          inherit mods;
          autoloads = "${(self.pack.getPackage package.compiler).spec.compiler_spec} ${(builtins.parseDrvName mpi.name).name} fftw openblase cmake dwarf-p-cloudsc";
        };
      mods = with final.pkgs;
        mkModules corePacks (with self.pack.pkgs; [
          compiler
          mpi
          fftw
          blas
          fiat
          cmake
          dwarf-p-cloudsc
        ]);
    })
