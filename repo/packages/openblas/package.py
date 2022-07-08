import spack.pkg.builtin.openblas as builtin

class Openblas(builtin.Openblas):
    patch('3550.patch', when='@0.3.17:0.3.20')

