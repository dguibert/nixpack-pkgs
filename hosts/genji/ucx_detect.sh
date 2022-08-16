#!/bin/sh -uex
if /usr/bin/ucx_info -b | /usr/bin/grep -- "$@"; then
  echo -n true > $out
else
  echo -n false > $out
fi
