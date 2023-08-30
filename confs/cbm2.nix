final:
# default HPCW
pack:
pack._merge (self:
    with self; {
      label = "cbm2_" + pack.label;
      repos = [
        final.cbm_repo
      ];

      package.boost.variants.mpi = true;
      # ctemplate dependency python: package python@3.9.13+bz2+ctypes+dbm~debug+libxml2+lzma~nis~optimizations+pic+pyexpat+pythoncmd+readline+shared+sqlite3+ssl~tix~tkinter~ucs4+uuid+zlib does not match dependency constraints {"version":":2"}
      package.ctemplate.version = "2.4"; # for python @3:
      #hemepure dependency tinyxml: package tinyxml@2.6.2~ipo+shared~stl build_type=RelWithDebInfo does not match dependency constraints {"variants":{"stl":true}}
      package.tinyxml.variants.stl = true;

      # hemocell dependency parmetis: package parmetis@4.0.3~gdb~int64~ipo+shared build_type=RelWithDebInfo does not match dependency constraints {"depends":{"metis":{"variants":{"shared":false}}},"variants":{"shared":false},"version":"4.0.3"}
      package.parmetis.variants.shared = false;
      package.metis.version = "5.1.0";

      package.hemepure.version = "git.15c93cf350424dcd0f2bdc0b6f4ba6876e339b5b=master";
      package.hemepure.variants.inlet_boundary = "NASHZEROTHORDERPRESSUREIOLET";
      package.hemepure.variants.outlet_boundary = "NASHZEROTHORDERPRESSUREIOLET";
      #package.hemepure.variants.wall_boundary = "SIMPLEBOUNCEBACK";
      #package.hemepure.variants.wall_inlet_boundary = "NASHZEROTHORDERPRESSURESBB";
      #package.hemepure.variants.wall_outlet_boundary = "NASHZEROTHORDERPRESSURESBB";
      package.hemepure.variants.wall_boundary = "BFL";
      package.hemepure.variants.wall_inlet_boundary = "NASHZEROTHORDERPRESSUREBFL";
      package.hemepure.variants.wall_outlet_boundary = "NASHZEROTHORDERPRESSUREBFL";

      mod_pkgs = with self.pack.pkgs; [
        compiler
        mpi
        cmake
        hemepure
        tinyxml
        parmetis
        boost
        ctemplate
        slms-loadbalancing
        libtirpc
      ];
    })
