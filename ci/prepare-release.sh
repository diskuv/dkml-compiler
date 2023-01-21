#!/bin/sh
set -eufx

# dist/
#   <dkml_target_abi>/
#      <file1>
#      ...

# The release directory structure should be based on the CI engine.
# - GitHub Releases are flat namespaces.
# - GitLab Packages can have two levels (the package name and the package file)

_release="$(pwd)/_release"
install -d "${_release}"

cd dist
if [ -n "${GITHUB_ENV:-}" ]; then
    # GitHub Releases
    #   Filename = Target_ABI '-' File
    find . -mindepth 1 -maxdepth 1 -type d | while read -r dkml_target_abi; do
        dkml_target_abi=$(basename "${dkml_target_abi}")
        find "${dkml_target_abi}" -mindepth 1 -maxdepth 1 -type f | while read -r file; do
          file=$(basename "${file}")
          install -v "${dkml_target_abi}/${file}" "${_release}/${dkml_target_abi}-${file}"
        done
    done
else
    # GitLab Packages (or PC)
    #   Package_Name = Target_ABI
    #   Package_File = File
    rsync -av "./" "${_release}"
fi
cd ..

# Display files to be distributed
cd _release
ls -R
cd ..
