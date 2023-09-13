import spack.pkg.builtin.python as builtin
import os
import sys

is_windows = sys.platform == "win32"


class Python(builtin.Python):
    version(
        "2.7.18",
        sha256="da3080e3b488f648a3d7a4560ddee895284c3380b11d6de75edb986526b9a814",
        deprecated=False, # to avoid failure with ignore_deprecation = tty.get_yes_or_no("  Fetch anyway?", default=False)
    )
    # Python needs to be patched to build extensions w/ mixed C/C++ code:
    # https://github.com/NixOS/nixpkgs/pull/19585/files
    # https://bugs.python.org/issue1222585
    #
    # NOTE: This patch puts Spack's default Python installation out of
    # sync with standard Python installs. If you're using such an
    # installation as an external and encountering build issues with mixed
    # C/C++ modules, consider installing a Spack-managed Python with
    # this patch instead. For more information, see:
    # https://github.com/spack/spack/pull/16856
    patch("python-2.7.8-distutils-C++.patch", when="@2.7.8:2.7.16")
    patch("python-2.7.17+-distutils-C++.patch", when="@2.7.17:2.7.18")
    patch("python-2.7.17+-distutils-C++-fixup.patch", when="@2.7.17:2.7.18")
    # Fixes an alignment problem with more aggressive optimization in gcc8
    # https://github.com/python/cpython/commit/0b91f8a668201fc58fa732b8acc496caedfdbae0
    patch("gcc-8-2.7.14.patch", when="@2.7.14 %gcc@8:")

    # For more information refer to this bug report:
    # https://bugs.python.org/issue29712
    conflicts(
        "@:2.8 +shared",
        when="+optimizations",
        msg="+optimizations is incompatible with +shared in python@2.X",
    )
    conflicts("+tix", when="~tkinter", msg="python+tix requires python+tix+tkinter")
    conflicts("%nvhpc")
    conflicts(
        "@:2.7",
        when="platform=darwin target=aarch64:",
        msg="Python 2.7 is too old for Apple Silicon",
    )

    # Used to cache various attributes that are expensive to compute
    _config_vars = {}  # type: Dict[str, Dict[str, str]]

    @when("@:2.99")
    def get_sysconfigdata_name(self):
        """Return the full path name of the sysconfigdata file."""

        libdest = self.config_vars["LIBDEST"]

        filename = "_sysconfigdata.py"
        if self.spec.satisfies("@3.6:"):
            # Python 3.6.0 renamed the sys config file
            cmd = "from sysconfig import _get_sysconfigdata_name; "
            cmd += self.print_string("_get_sysconfigdata_name()")
            filename = self.command("-c", cmd, output=str).strip()
            filename += ".py"

        return join_path(libdest, filename)

    @when("@:2.99")
    @run_after("install")
    def symlink(self):
        # python2 -> python already
        pass



