{lib, ...}: rec {
  fix = f: let fixpoint = f fixpoint; in fixpoint;
  withOverride = overrides: f: self:
    f self
    // (
      if builtins.isFunction overrides
      then overrides self
      else overrides
    );

  withMerge = overrides: f: self:
    recursiveMerge [
      (f self)
      (
        if builtins.isFunction overrides
        then overrides self
        else overrides
      )
    ];

  # http://r6.ca/blog/20140422T142911Z.html
  virtual = f:
    fix f
    // {
      _override = overrides: virtual (withOverride overrides f);
      _merge = overrides: virtual (withMerge overrides f);
    };

  recursiveMerge = attrList: let
    f = attrPath:
      with lib;
        zipAttrsWith (
          n: values:
            if tail values == []
            then head values
            else if all isList values
            then unique (concatLists values)
            else if all isAttrs values
            then f (attrPath ++ [n]) values
            else last values
        );
  in
    f [] attrList;
}
