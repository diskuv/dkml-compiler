.PHONY: all
all: install

.PHONY: create-switch
create-switch: _opam/.opam-switch/switch-config

#   Force an update since 'opam switch create' only updates when it newly registers the repository
_opam/.opam-switch/switch-config:
	opam switch create . --empty --repos diskuv=git+https://github.com/diskuv/diskuv-opam-repository.git#main,default=https://opam.ocaml.org
	opam update diskuv

.PHONY: install
install: create-switch
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam pin ocaml -k version 4.14.0 --no-action --yes && \
	  rm -rf _opam/src-ocaml && \
	  opam install ./ocaml.opam ./dkml-base-compiler.opam --keep-build-dir --yes

.PHONY: local-install
local-install: create-switch
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam pin ocaml -k version 4.14.0 --no-action --yes && \
	  rm -rf dkmldir Brewfile _opam/src-ocaml && \
	  opam install ./ocaml.opam ./dkml-base-compiler.opam --inplace-build --keep-build-dir --yes
