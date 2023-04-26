{
  lib,
  nixpack_lib,
}: let
  virtual_lib = import ./virtual.nix {inherit lib;};
in
  lib
  // nixpack_lib
  // virtual_lib
  // rec {
    loadPacks =
      prev: dir:
        with lib;
        with builtins; let
          content = readDir dir;
          filtered = filterAttrs (key: val: ! hasPrefix "." key && (hasSuffix ".nix" key || val == "directory")) content;
          out = attrNames filtered;
        in
          /*
           if pathExists dir then
           */
          listToAttrs (map (n: {
              name = replaceStrings [".nix"] [""] n;
              value = removeAttrs (prev.callPackage (dir + "/${n}") {}) ["override"];
            })
            out)
      /*
       else {}
       */
      ;

    packsFun = nixpack_lib.packs;

    isLDep = builtins.elem "link";
    isRDep = builtins.elem "run";
    isRLDep = d: isLDep d || isRDep d;

    rpmVersion = pkg: nixpack_lib.capture ["/bin/rpm" "-q" "--queryformat=%{VERSION}" pkg] {};
    rpmExtern = pkg: {
      extern = "/usr";
      version = rpmVersion pkg;
    };

    findModDeps = pkgs:
      with lib;
      with builtins; let
        mods = unique (map (x: addPkg x) pkgs);
        addPkg = x:
          if x ? spec
          then
            if x.spec.extern == null
            then {pkg = x;}
            else
              /*
               builtins.trace "addPkg: ${nixpkgs.lib.generators.toPretty { allowPrettyValues=true; } x.spec}"
               */
              {
                pkg = x;
                projection = "${x.spec.name}/${x.spec.version}";
              }
          else x;
        pred = x: (isRLDep (x.pkg.deptype or []));

        pkgOrSpec = p: p.pkg.spec or p;
        adddeps = s: pkgs:
          add s
          (
            filter
            (p:
              /*
               builtins.trace "adddeps: ${nixpkgs.lib.generators.toPretty { allowPrettyValues = true; } p}"
               */
                p
                != null
                && ! (any (x: pkgOrSpec x == pkgOrSpec p) s)
                && pred p)
            (
              nixpack_lib.nubBy (x: y: pkgOrSpec x == pkgOrSpec y)
              (concatMap
                (
                  p:
                    map (x: addPkg x)
                    (attrValues (p.pkg.spec.depends or {}))
                )
                pkgs)
            )
          );
        add = s: pkgs:
          if pkgs == []
          then s
          else adddeps (s ++ pkgs) pkgs;
      in
        add [] (toList mods);
  }
