{pkgs, ...}: {
  package = {
    #/* must be set to an external compiler capable of building compiler (above) */
    #compiler = {
    #  name = "gcc";
    #  extern=pkgs.gcc;
    #  version=pkgs.gcc.version;
    #};
  };
}
