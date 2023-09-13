import spack.pkg.builtin.intel_oneapi_compilers_classic as builtin

class IntelOneapiCompilersClassic(builtin.IntelOneapiCompilersClassic):
    pass
    def setup_run_environment(self, env):
        """Adds environment variables to the generated module file.

        These environment variables come from running:
        .. code-block:: console
           $ source {prefix}/{component}/{version}/env/vars.sh
        and from setting CC/CXX/F77/FC
        """
        oneapi_pkg = None
        if "oneapi" in self.spec:
            oneapi_pkg = self.spec["oneapi"].package
        else:
            oneapi_pkg = self.spec["intel-oneapi-compilers"].package

        oneapi_pkg.setup_run_environment(env)

        bin_prefix = oneapi_pkg.component_prefix.linux.bin.intel64
        env.set("CC", bin_prefix.icc)
        env.set("CXX", bin_prefix.icpc)
        env.set("F77", bin_prefix.ifort)
        env.set("FC", bin_prefix.ifort)
