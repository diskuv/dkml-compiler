#!/bin/sh
set -euf

dkml_host_abi=$1
shift
prefix=$1
shift

install -d dist

case "${dkml_host_abi}" in
    windows_*)
        if command -v pacman; then
            pacman -Sy --noconfirm --needed zip
        fi ;;
esac

bundle_up() {
    bundle_up_ABI=$1
    shift
    case "${dkml_host_abi}" in
        windows_*)
            cd "stage/${bundle_up_ABI}"
            zip -rq "../../dist/bin.$bundle_up_ABI.zip" .
            cd ../..
            ;;
        *)
            tar cCfz "stage/${bundle_up_ABI}" "dist/bin.$bundle_up_ABI.tar.gz" .
    esac
}

copyabi() {
    copyabi_ABI=$1
    shift
    copyabi_DIR=$1
    shift
    for dir in bin lib/findlib.conf.d lib/ocaml lib/stublibs lib/toplevel man share/dkml-base-compiler share/doc share/ocaml-config; do
        if [ -e "$copyabi_DIR/$dir" ]; then
            dn=$(dirname "$dir")
            install -d "stage/${copyabi_ABI}/$dn"
            cp -rp "$copyabi_DIR/$dir" "stage/${copyabi_ABI}/$dn/"
        fi
    done
}

copyabi "$dkml_host_abi" "$prefix"

find "$prefix" -mindepth 1 -maxdepth 1 -name "*-sysroot" | while read -r sysroot; do
    target_abi=$(basename "$sysroot" | sed s/-sysroot//)

    # sysroot are files that are compiled for the target ABI ... they
    # do not run on the host ABI (unless Rosetta or another emulator is present)
    cp -rp "$sysroot" "stage/${dkml_host_abi}/$target_abi-sysroot"

    # mlcross are compiled for the host ABI but generate files for
    # the target ABI. They do run on the host ABI.
    copyabi "${dkml_host_abi}_X_$target_abi" "$prefix/share/dkml-base-compiler/mlcross/$target_abi"
    bundle_up "${dkml_host_abi}_X_$target_abi"
done

# We have to delay creating this in case there were any -sysroot folders
tar cCfz "stage/${dkml_host_abi}" "dist/bin.$dkml_host_abi.tar.gz" .
bundle_up "$dkml_host_abi"

# ----------- ocamlc.opt

install "$prefix/bin/ocamlc.opt${exe_ext:-}" "dist/$dkml_host_abi-ocamlc.opt${exe_ext:-}"
