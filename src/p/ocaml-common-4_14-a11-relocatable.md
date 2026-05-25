# ocaml-common-4_14 relocatable patch series

Source: dra27 `relocatable-compiler.4.14.3.20251109.1` on branch `backport-4.14`.
These grouped patches replace the old monolithic relocatable patch for the DkML 4.14.3 build.

## ocaml-common-4_14-a11-relocatable-version-build.patch

- `5fe7f0fbcbadb25089d543267346d09d602d0dfa` OCaml 4.14.3+relocatable base version commit
- `1293d8c6d8a2e62226c2d0637e839c4c0eeda32f` Generate an OCaml quoted string ID in configure
- `c299bcb4c6ad06712072c973728697203bb55751` Compute LN during configure rather than during build
- `d6017abc06c20a339a6336603a584babbe08d67f` Compute $(STDLIB_MODULES) with GNU make functions
- `216ea2bd217ebe6da67c7472ad124740a1e9fdb4` Add ax_check_compile_flag.m4

## ocaml-common-4_14-a12-relocatable-launcher.patch

- `2889fc8ecf501e52b228e7690981d12bccba6aa3` headernt.c: fix segmentation fault when runtime not found
- `764a319677b982df3b8d54349f88550b99b80683` Implement --with-target-bindir
- `13b4de4b82944fa312f8030acaaccf5bf1d39bfd` Eliminate warning in stdlib/header.c
- `f08c2574a355dd637fa5f30c0b5ebd274933d296` Compute the bytecode launcher stub in ocamlc
- `62921f3939c17f16078789d4abc0856cf82b1984` Remove last vestiges of camlheader post-bootstrap
- `2ef756f3b6537307e5b6779d1ee28760845509c0` Partially enable shebang headers on Cygwin
- `305a7e98425de659d8cfd9cf93e9b3d65274f26d` Explicitly compile the primitives object
- `ecc8900ba820a5f1582034e6da8d5b632ef3c5f4` Don't include the flexdll directory with -nostdlib
- `8af81bc481e78c4a17df0d18972f129b671e9ce8` Include CAML_LD_LIBRARY_PATH in ocamlrun -config
- `372e5f98d1b5fd7472b776a501bbd19c341d9d95` Create symlinks on Windows when available
- `eaefc68a2cfd72556a74dbc2c0daa317cdf0ed0d` Set MSYS and CYGWIN permanently
- `e4f44b9c58cd5a3935c6bcca59316b743c6a0954` Correct OOM semantics of caml_stat_strdup_to_os
- `2db0656f1a24f3e13e23581547d77cb483462e08` Add caml_stat_char_array_{to,of}_os
- `93101845dbc2c44630dbc42c6dc89fbf127f8263` Rename target_bindir to TARGET_BINDIR in configure
- `8d5c1cbb2e8cd10b214ea52481a98d2c44bca705` Add a configurable library directory on target
- `a442252cdeb9285772cf0207dbf87686af39d4cc` Fix backslashes in runtime/build_config.h
- `843c73867ea50e4782acae7b0d791d47dfb629c0` Move TARGET_LIBDIR to Makefile.build_config
- `1401ab9b174f3fc3e5a819dd4054899ba2553a7a` Reduce tmpheader.exe to 4-5KiB on Windows
- `f37343978547d0afe277107dd6d5876a60dad320` Make caml/exec.h independent
- `34a279109e18808ef964b8c24176510bdb09ec22` Unify the common parts of header.c and headernt.c
- `ace4fd0220d32bfa3c5758e45c8f1cad812a29bb` Merge stdlib/header{,nt}.c
- `5f6b3010176f2844402d824962de1b3d587b57ca` Add Compmisc.reinit_path
- `4421aa9e45b2b8a02d4ef5dbd2f94801254d1007` Add Dll.search_path

## ocaml-common-4_14-a13-relocatable-stdlib.patch

- `83ef73ac97ee12d64b96ef9ecec478fc131915e2` Add --with-stublibs configure option
- `1f812fd12574c96478ac6efa9d10ed48abfb6e59` Don't add a double-separator when locating ld.conf
- `0a330a1d092e77592a6dc3ff5bd268d69e35a29d` ld.conf-relative path interpretation
- `ad6f26e823df8a5113533b41b17eb49bc1a49c45` Generate ld.conf using relative paths
- `29953ab3d06e23d4b035bb360f74597c3b5862ba` Load ld.conf from all possible places
- `a0d6f301918a475fa04a99373566e23089b11474` Remove caml_get_stdlib_location
- `f70e03a4294198975f6dc28cf13a6cd2b5c0d15d` Harden the parsing of ld.conf w.r.t. load and CRLF
- `c0e2a55eb7e1126b829bd99f08f7a0cbfe1d1830` Use caml_parse_ld_conf in ocamlc
- `a49c51aa6d1c7b8e5c5575ef493ecbc5f851164c` Tidy installation of static builds
- `5153b63834ae00f375024edfe5a8db159343e648` Fix the detection of Cygwin-like build environments
- `8be40e5bafdb912b0c968be6ed57331f26e942ae` Preserve backslashes in --prefix
- `b790ab168a98c407b3bc1ef59be93329aaf5917a` Interpret . in runtime-launch-info
- `07c80d1a250d3df0fea614ba2701cd39b64a348d` Harden startup of -custom executables
- `362016cd14408bffc72c2f3c6b8e02bf6bfe2a6a` Add caml_runtime_standard_library_default
- `91e9eaa0144343b610617e51f5fae3ef6df08614` Add %standard_library_default
- `daf11d83ee44a21af9dea5cf97103803356a07fd` Add -set-runtime-default
- `2b3e560c606a9711f53999f0fa4c44c40cf68b70` Use %standard_library_default in Config
- `560e75146f21ed55db83b423c270c6b35e44c7a9` Allow libdir to be found relative to bindir
- `c10de95c9a6f033260f7c929e50c545e291fc011` Use as directly on Cygwin, as on Linux
- `2ef1a8c0d22da0b033684f2efeb0641773f30228` Detect but ignore -fdebug-prefix-map on mingw-w64
- `59a0f97202c1d46b67dd80a17e80eba3d972fa67` Add Config.as_is_cc
- `30286fe7b0df0b9e490a452f5a72bfbce021f55d` Increase reproducibility of relative artefacts

## ocaml-common-4_14-a14-relocatable-runtime-search.patch

- `690462ce02accc6605ee13412143d6ea23a4d1c5` Fix OmniOS fallback to /bin/sh
- `26d5046038177f382816f39ee9b71231fb78788f` Simplify the computation for the runtime name
- `4f88fb25d2562321194424f2b4f3d169ce2c6a44` Permit single-quotes in prefix
- `09a468ea296712f90e45ddb2d8504af13c2e5cce` ocamlobjinfo: display the runtime used by an image
- `5426c65e637f77794f956e818ccd25e2c78c99e5` Add -launch-method to ocamlc
- `e466837dd52ed37ad5ae2174a858d42ceb134ed3` Remove metadata from runtime-launch-info
- `a0fde548826f2d2ed2535fa6f70ab1e876ddd43b` Factor out the exec code in stdlib/header.c
- `9ca8a0e27e1eff6e81eaf6a5b926cf9be5ab7e33` Add -runtime-search to ocamlc
- `ae613c5cdd0698346e75c90f6668f3b8d95294b5` Determine Runtime ID values in configure
- `222c2bdbbce70954573620500cd91647ae1c75da` Mangle the bytecode runtime executable names
- `6bdd0c577d9efe402e067acfdfcd94c88e70406b` Build suffixed shared runtimes
- `0ece2fc8ea81d8597548d227358ed0c3408983bc` Add runtime suffixes to bytecode stub libraries
- `a1b7e3872ecbf15023c252ef2e8a7d6d6de10484` Post-bootstrap cleanup
- `7fadc290d3557b242f47e1e64d27ebe792e12b00` Add --enable-runtime-search[-target] options
- `d9d13c31587b656dbf33b427bb00c6ab168e7d02` Make Windows header absolute (as on Unix)

## ocaml-common-4_14-a15-relocatable-install.patch

- `f00dd6d9a69901d40eedfc5d17044ffbe3d68ddb` Don't install two different bigarray.mli files
- `0508857ea81fddb1b695319da039e43a9f511a0c` Don't explicitly install toplevel/byte/*.cmi
- `8299bf587f059f653427ba00e6302cc1c73426fb` Don't explicitly install main.cmx and optmain.cmx
- `ab77eb816cb496bc1ae9431ae4e71490b7f51e88` Remove duplicate installation in installopt
- `0d52e9a89a75ddc273bc294dfa6060e86954f665` Don't install ocamldoc's .cmi files twice
- `9ccc688648ae430e3317a800c33aff94172e1f32` Use implicit names when installing ocamldoc
- `b685d47d921c7c889b660bfdef2794736ba0c206` Eliminate local for loops in install
- `27c9c71c8cd02e28697a811f9371da274ec945f0` Eliminate local if blocks in install
- `8cb41695e88d8b2e98364938fcf5223428050968` Remove invalid directory in source install
- `ab60563ccc3845950de124f36793b1508039eed5` Sprinkle some meta-programming on the install target
- `bea4e014ab648224eabfd2e008f24f632aff53ff` Straighten out the INSTALL_* Makefile variables
- `dc763cf36fa28f56ac63dfc8d04cbf25554a7c7d` Remove the recursive invocation in install targets
- `0e4400c3a0bfac41b4d5f7f888bf6366949d4af4` Add SUBDIR_NAME to principal Makefiles
- `8088d599bbc2a09b02d4b9288028d0f330166135` Use macros to generate installation commands
- `ae24640521ffc42ed61d0e5746215f2987e2c8e7` Add additional modes to make install

