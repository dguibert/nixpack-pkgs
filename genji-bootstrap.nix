{ rpmExtern
}: {
  package = {
    /* must be set to an external compiler capable of building compiler (above) */
    compiler = {
      name = "gcc";
    } // rpmExtern "gcc";

    ncurses = rpmExtern "ncurses" // {
      variants = {
        termlib = false;
        abi = "5";
      };
    };
  };
}
