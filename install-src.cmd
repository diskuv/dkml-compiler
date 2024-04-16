SETLOCAL ENABLEEXTENSIONS

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
COPY /Y /B src\r-c-ocaml-1-setup.sh %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\r-c-ocaml-2-build_host.sh %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\r-c-ocaml-3-build_cross.sh %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\r-c-ocaml-9-trim.sh %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\r-c-ocaml-README.md %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\r-c-ocaml-check_linker.sh %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\r-c-ocaml-functions.sh %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\r-c-ocaml-get_sak.make %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\version.ocaml.txt %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\version.semver.txt %TARGETDIR%\src
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)


IF NOT EXIST "%TARGETDIR%\src\f" MKDIR %TARGETDIR%\src\f
COPY /Y /B src\f\setjmp.asm %TARGETDIR%\src\f
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)


IF NOT EXIST "%TARGETDIR%\src\p" MKDIR %TARGETDIR%\src\p
COPY /Y /B src\p\flexdll-cross-0_39-a01-arm64.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\flexdll-cross-0_42-a01-arm64.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-common-4_12-a01-alignfiletime.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-common-4_14_0-a01-fmatest.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-common-4_14-a01-alignfiletime.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-common-4_14-a02-nattop.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-common-4_14-a03-keepasm.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-common-4_14-a04-xdg.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-common-4_14-a05-msvccflags.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-4_12-a01.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-4_12-a02-arm32.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-4_12unused-zzz-win32arm.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-4_13-a01.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-4_14-a01.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-4_14_0-a02-arm32.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-4_14_2-a02-arm32.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B src\p\ocaml-cross-5_00_a02-arm32.patch %TARGETDIR%\src\p
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)


IF NOT EXIST "%TARGETDIR%\env" MKDIR %TARGETDIR%\env
COPY /Y /B env\github-actions-ci-to-ocaml-configure-env.sh %TARGETDIR%\env
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)
COPY /Y /B env\standard-compiler-env-to-ocaml-configure-env.sh %TARGETDIR%\env
IF %ERRORLEVEL% NEQ 0 (ECHO Error during COPY &EXIT /B 1)

