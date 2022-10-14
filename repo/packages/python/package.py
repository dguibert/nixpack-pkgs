import spack.pkg.builtin.python as builtin

class Python(builtin.Python):
    version(
        "2.7.18",
        sha256="da3080e3b488f648a3d7a4560ddee895284c3380b11d6de75edb986526b9a814",
        deprecated=False, # to avoid failure with ignore_deprecation = tty.get_yes_or_no("  Fetch anyway?", default=False)
    )

