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
      package.hdf5.version = "1.12";
      package.ecbuild.version = "3.6.5"; # FIXME used package from spack instead of hpcw
      package.eckit.version = "1.20";
      package.fckit.version = "0.10.1";

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        fftw
        blas
        fiat
        cmake
        dwarf-p-cloudsc
      ];
    })
