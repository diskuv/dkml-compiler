# Test with:
# cmake --log-context -D DRYRUN=1 -D CMAKE_MESSAGE_CONTEXT=dkml-compiler -D "regex_DKML_VERSION_SEMVER=1[.]2[.]1-[0-9]+" -D "regex_DKML_VERSION_OPAMVER=1[.]2[.]1[~]prerel[0-9]+" -D DKML_VERSION_SEMVER_NEW=1.2.1-3 -D DKML_VERSION_OPAMVER_NEW=1.2.1~prerel3 -D GIT_EXECUTABLE=git -D DKML_RELEASE_OCAML_VERSION=4.14.2 -D DKML_BUMP_VERSION_PARTICIPANT_MODULE=../../pkg/bump/DkMLBumpVersionParticipant.cmake -P bump-version.cmake

if(NOT DKML_BUMP_VERSION_PARTICIPANT_MODULE)
    message(FATAL_ERROR "Missing -D DKML_BUMP_VERSION_PARTICIPANT_MODULE=.../DkMLBumpVersionParticipant.cmake")
endif()
include(${DKML_BUMP_VERSION_PARTICIPANT_MODULE})

DkMLBumpVersionParticipant_PlainReplace(src/version.semver.txt)
DkMLBumpVersionParticipant_OCamlVersionReplace(src/version.ocaml.txt)
DkMLBumpVersionParticipant_PlainReplace(dkml-compiler-src.META)
DkMLBumpVersionParticipant_OpamReplace(dkml-compiler-env.opam)
DkMLBumpVersionParticipant_OpamReplace(dkml-compiler-src.opam)
DkMLBumpVersionParticipant_DkmlBaseCompilerReplace(dkml-base-compiler.opam)
DkMLBumpVersionParticipant_GitAddAndCommit()
