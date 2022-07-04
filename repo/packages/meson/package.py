import spack.pkg.builtin.meson as builtin

class Meson(builtin.Meson):
    patch('10056.patch', when='@0.60:')
