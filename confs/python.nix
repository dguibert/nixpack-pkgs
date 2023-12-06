final: pack:
pack._merge (self:
    with self; {
      label = "python_" + pack.label;

      package.python.version = "3.11";
      mod_pkgs = with self.pack.pkgs; [
        compiler
        python
      ];
    })
