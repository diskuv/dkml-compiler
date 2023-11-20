function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")
    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    message(${ARG_MODE} [[usage: ./dk user.reindex

Recreate install-src.cmd and install-src.sh which have an
index of patches and source code.

Arguments
=========

HELP
  Print this help message.
]])
endfunction()

function(reindex_install_src_sh)
    set(noValues)
    set(singleValues)
    set(multiValues LISTING_SRC LISTING_SRC_F LISTING_SRC_P LISTING_ENV)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(listing_src ${ARG_LISTING_SRC})
    set(listing_src_f ${ARG_LISTING_SRC_F})
    set(listing_src_p ${ARG_LISTING_SRC_P})
    set(listing_env ${ARG_LISTING_ENV})
    set(template [[#!/bin/sh

targetdir=$1
shift

echo -- ---------------------
echo Arguments:
echo "  Target directory = $targetdir"
echo -- ---------------------

install -d "$targetdir"
install -v dkml-compiler-src.META "$targetdir/META"

install -d "$targetdir/src"
install -v \
@INSTALL_SRC@    "$targetdir/src"

install -d "$targetdir/src/f"
install -v \
@INSTALL_SRC_F@    "$targetdir/src/f"

install -d "$targetdir/src/p"
install -v \
@INSTALL_SRC_P@    "$targetdir/src/p"

install -d "$targetdir/env"
install -v \
@INSTALL_ENV@    "$targetdir/env"
]])

    foreach(listing_VARNAME IN ITEMS listing_src listing_src_f listing_src_p listing_env)
        list(TRANSFORM ${listing_VARNAME} PREPEND "    ")
        list(TRANSFORM ${listing_VARNAME} APPEND " \\\n")
    endforeach()

    string(CONCAT INSTALL_SRC ${listing_src})
    string(CONCAT INSTALL_SRC_F ${listing_src_f})
    string(CONCAT INSTALL_SRC_P ${listing_src_p})
    string(CONCAT INSTALL_ENV ${listing_env})

    file(CONFIGURE OUTPUT ${CMAKE_SOURCE_DIR}/install-src.sh CONTENT "${template}" @ONLY NEWLINE_STYLE UNIX)
    file(CHMOD ${CMAKE_SOURCE_DIR}/install-src.sh
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endfunction()

function(reindex_install_src_cmd)
    set(noValues)
    set(singleValues)
    set(multiValues LISTING_SRC LISTING_SRC_F LISTING_SRC_P LISTING_ENV)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(listing_src ${ARG_LISTING_SRC})
    set(listing_src_f ${ARG_LISTING_SRC_F})
    set(listing_src_p ${ARG_LISTING_SRC_P})
    set(listing_env ${ARG_LISTING_ENV})
    set(template [[SETLOCAL ENABLEEXTENSIONS

@ECHO ---------------------
@ECHO Arguments:
@ECHO   Target directory = %1
@ECHO ---------------------
SET TARGETDIR=%1

@REM Using MKDIR will create any parent directories (extensions are enabled)
@REM Using COPY /B is binary mode so that CRLF is not added

IF NOT EXIST "%TARGETDIR%" MKDIR %TARGETDIR%
COPY /Y /B dkml-compiler-src.META %TARGETDIR%\META
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)

IF NOT EXIST "%TARGETDIR%\src" MKDIR %TARGETDIR%\src
@INSTALL_SRC@

IF NOT EXIST "%TARGETDIR%\src\f" MKDIR %TARGETDIR%\src\f
@INSTALL_SRC_F@

IF NOT EXIST "%TARGETDIR%\src\p" MKDIR %TARGETDIR%\src\p
@INSTALL_SRC_P@

IF NOT EXIST "%TARGETDIR%\env" MKDIR %TARGETDIR%\env
@INSTALL_ENV@
]])

    foreach(listing_VARNAME IN ITEMS listing_src listing_src_f listing_src_p listing_env)
        list(TRANSFORM ${listing_VARNAME} REPLACE "/" "\\\\")
        list(TRANSFORM ${listing_VARNAME} PREPEND "COPY /Y /B ")
    endforeach()

    list(TRANSFORM listing_src APPEND " %TARGETDIR%\\src\nIF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)\n")
    list(TRANSFORM listing_src_f APPEND " %TARGETDIR%\\src\\f\nIF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)\n")
    list(TRANSFORM listing_src_p APPEND " %TARGETDIR%\\src\\p\nIF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)\n")
    list(TRANSFORM listing_env APPEND " %TARGETDIR%\\env\nIF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)\n")

    string(CONCAT INSTALL_SRC ${listing_src})
    string(CONCAT INSTALL_SRC_F ${listing_src_f})
    string(CONCAT INSTALL_SRC_P ${listing_src_p})
    string(CONCAT INSTALL_ENV ${listing_env})

    file(CONFIGURE OUTPUT ${CMAKE_SOURCE_DIR}/install-src.cmd CONTENT "${template}" @ONLY NEWLINE_STYLE DOS)
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(CMAKE_CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CURRENT_FUNCTION})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP" "" "")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # Gather source code listings
    file(GLOB listing_src LIST_DIRECTORIES false RELATIVE ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/src/*.sh
        ${CMAKE_SOURCE_DIR}/src/*.make
        ${CMAKE_SOURCE_DIR}/src/r-c-ocaml-README.md
        ${CMAKE_SOURCE_DIR}/src/version.ocaml.txt
        ${CMAKE_SOURCE_DIR}/src/version.semver.txt)
    file(GLOB listing_src_f LIST_DIRECTORIES false RELATIVE ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/src/f/*.asm)
    file(GLOB listing_src_p LIST_DIRECTORIES false RELATIVE ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/src/p/*.patch)
    file(GLOB listing_env LIST_DIRECTORIES false RELATIVE ${CMAKE_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/env/*.sh)

    # Rewrite source files containing indexes
    reindex_install_src_sh(
        LISTING_SRC ${listing_src}
        LISTING_SRC_F ${listing_src_f}
        LISTING_SRC_P ${listing_src_p}
        LISTING_ENV ${listing_env})
    reindex_install_src_cmd(
        LISTING_SRC ${listing_src}
        LISTING_SRC_F ${listing_src_f}
        LISTING_SRC_P ${listing_src_p}
        LISTING_ENV ${listing_env})
endfunction()
