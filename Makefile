all: install

create-switch: _opam/.opam-switch/switch-config

_opam/.opam-switch/switch-config:
	opam switch create . --empty --repo default=https://opam.ocaml.org

install: create-switch
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam pin add ocaml -k version 4.12.1 --no-action --yes && \
	  opam install ./ocaml.opam ./dkml-base-compiler.opam --yes
