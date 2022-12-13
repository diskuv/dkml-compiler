.PHONY: all
all: install

.PHONY: create-switch
create-switch: _opam/.opam-switch/switch-config

_opam/.opam-switch/switch-config:
	opam switch create . --empty --repo default=https://opam.ocaml.org,diskuv=git+https://github.com/diskuv/diskuv-opam-repository.git#main

.PHONY: install
install: create-switch
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam pin ocaml -k version 4.14.0 --no-action --yes && \
	  opam install ./ocaml.opam ./dkml-base-compiler.opam --yes

.PHONY: local-install
local-install: create-switch
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam pin ocaml -k version 4.14.0 --no-action --yes && \
	  opam install ./ocaml.opam ./dkml-base-compiler.opam --inplace-build --keep-build-dir --yes
