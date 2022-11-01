SETLOCAL ENABLEEXTENSIONS

@ECHO ---------------------
@ECHO Arguments:
@ECHO   Target directory = %1
@ECHO ---------------------
SET TARGETDIR=%1

@REM Create target dir including any parent directories (extensions are enabled)
MKDIR %TARGETDIR%

@REM Copy in binary mode so that CRLF is not added
COPY /Y /B env\META                                             %TARGETDIR%
COPY /Y /B env\github-actions-ci-to-ocaml-configure-env.sh      %TARGETDIR%
COPY /Y /B env\standard-compiler-env-to-ocaml-configure-env.sh  %TARGETDIR%
