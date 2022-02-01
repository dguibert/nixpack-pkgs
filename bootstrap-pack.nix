{ corePacks
, rpmExtern
, extraConf ? {}
}: corePacks.withPrefs {
  label = "bootstrap";
  global = {
    resolver = null;
    tests = false;
  };
  package = {}
  // (extraConf.package or {});
}


