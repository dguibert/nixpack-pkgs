{
  corePacks,
  rpmExtern,
  extraConf ? {},
}: let
  self = corePacks.withPrefs {
    label = "bootstrap";
    global = {
      resolver = null;
      tests = false;
    };
    package =
      {
        # for gcc bootstrap
        texinfo.depends.compiler = self.pkgs.compiler;
        berkeley-db.depends.compiler = self.pkgs.compiler;
        perl.depends.compiler = self.pkgs.compiler;
        readline.depends.compiler = self.pkgs.compiler;
        zlib.depends.compiler = self.pkgs.compiler;
        gdbm.depends.compiler = self.pkgs.compiler;
        gdbm.version = "1.19"; # for perl
      }
      // (extraConf.package or {});
  };
in
  self
