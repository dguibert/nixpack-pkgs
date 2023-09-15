import spack.pkg.builtin.rust as builtin
import os

class Rust(builtin.Rust):
    def setup_build_environment(self, env):
        # Manually inject the path of ar for build.
        ar = which("ar", required=True)
        env.set("AR", ar.path)
        # Manually inject the path of openssl's certs for build.
        certs = join_path(self.spec["openssl"].prefix, "etc/openssl/cert.pem")
        if os.path.exists(certs):
            env.set("CARGO_HTTP_CAINFO", certs)

