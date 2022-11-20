#!/bin/sh
#
# ----------------------------
# Copyright 2021 Diskuv, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------
#
######################################
# r-c-ocaml-9-trim.sh -d DKMLDIR -t TARGETDIR [-z]
#
# Purpose:
# 1. If and only if [-z] is specified then remove source code from the target directory
#
# -------------------------------------------------------
set -euf

# ------------------
# BEGIN Command line processing

usage() {
    {
        printf "%s\n" "Usage:"
        printf "%s\n" "    r-c-ocaml-9-trim.sh"
        printf "%s\n" "        -h             Display this help message."
        printf "%s\n" "        -d DIR -t DIR  Trim OCaml."
        printf "\n"
        printf "%s\n" "See 'r-c-ocaml-1-setup.sh -h' for more comprehensive docs."
        printf "\n"
        printf "%s\n" "Options"
        printf "%s\n" "   -d DIR: DKML directory containing a .dkmlroot file"
        printf "%s\n" "   -t DIR: Target directory for the reproducible directory tree"
        printf "%s\n" "   -f HOSTSRC_SUBDIR: Use HOSTSRC_SUBDIR subdirectory of -t DIR to place the source code of the host ABI"
        printf "%s\n" "   -g CROSS_SUBDIR: Use CROSS_SUBDIR subdirectory of -t DIR to place target ABIs"
        printf "%s\n" "   -x Do not include temporary object files (only useful for debugging) in target directory"
        printf "%s\n" "   -z Do not include .git repositories in target directory"
    } >&2
}

DKMLDIR=
TARGETDIR=
HOSTSRC_SUBDIR=
CROSS_SUBDIR=
REMOVE_OBJECTFILES=OFF
REMOVE_GITDIR=OFF
while getopts ":d:t:f:g:xzh" opt; do
    case ${opt} in
        h )
            usage
            exit 0
        ;;
        d )
            DKMLDIR="$OPTARG"
            if [ ! -e "$DKMLDIR/.dkmlroot" ]; then
                printf "%s\n" "Expected a DKMLDIR at $DKMLDIR but no .dkmlroot found" >&2;
                usage
                exit 1
            fi
            DKMLDIR=$(cd "$DKMLDIR" && pwd) # absolute path
        ;;
        t )
            TARGETDIR="$OPTARG"
        ;;
        f ) HOSTSRC_SUBDIR=$OPTARG ;;
        g ) CROSS_SUBDIR=$OPTARG ;;
        x ) REMOVE_OBJECTFILES=ON ;;
        z ) REMOVE_GITDIR=ON ;;
        \? )
            printf "%s\n" "This is not an option: -$OPTARG" >&2
            usage
            exit 1
        ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$DKMLDIR" ] || [ -z "$TARGETDIR" ] || [ -z "$HOSTSRC_SUBDIR" ] || [ -z "$CROSS_SUBDIR" ]; then
  printf "%s\n" "Missing required options" >&2
  usage
  exit 1
fi

# END Command line processing
# ------------------

# shellcheck disable=SC1091
. "$DKMLDIR/vendor/drc/unix/crossplatform-functions.sh"

disambiguate_filesystem_paths

# Bootstrapping vars
TARGETDIR_UNIX=$(cd "$TARGETDIR" && pwd) # better than cygpath: handles TARGETDIR=. without trailing slash, and works on Unix/Windows
if [ -x /usr/bin/cygpath ]; then
    # Makefiles have very poor support for Windows paths, so use mixed (ex. C:/Windows) paths
    OCAMLSRC_MIXED=$(/usr/bin/cygpath -am "$TARGETDIR_UNIX/$HOSTSRC_SUBDIR")
    CROSSSRC_MIXED=$(/usr/bin/cygpath -am "$TARGETDIR_UNIX/$CROSS_SUBDIR")
else
    OCAMLSRC_MIXED="$TARGETDIR_UNIX/$HOSTSRC_SUBDIR"
    CROSSSRC_MIXED="$TARGETDIR_UNIX/$CROSS_SUBDIR"
fi

# ------------------

if [ "$REMOVE_OBJECTFILES" = ON ]; then
    # Clean up excess files, including git submodules and cross-compiled targets
    git -C "$OCAMLSRC_MIXED" clean -d -f -x
    git -C "$OCAMLSRC_MIXED" submodule foreach --recursive "git clean -d -f -x -"
    if [ -d "$CROSSSRC_MIXED" ]; then
        find "$CROSSSRC_MIXED" -mindepth 1 -maxdepth 1 -type d -print0 | xargs -r0 -n1 -I{} git -C {} clean -d -f -x
        find "$CROSSSRC_MIXED" -mindepth 1 -maxdepth 1 -type d -print0 | xargs -r0 -n1 -I{} git -C {} submodule foreach --recursive "git clean -d -f -x -"
    fi
fi

if [ "$REMOVE_GITDIR" = ON ]; then
    find "$OCAMLSRC_MIXED" -name .git -type d -print0 | xargs -r0 -- rm -rf
    if [ -d "$CROSSSRC_MIXED" ]; then
        find "$CROSSSRC_MIXED" -name .git -type d -print0 | xargs -r0 -- rm -rf
    fi
fi
