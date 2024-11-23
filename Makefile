OPTION_PACKAGES = dkml-option-debuginfo

.PHONY: all
all: install

.PHONY: clean
clean:
	rm -rf _opam _build dkmldir dist Brewfile msys64 stage

.PHONY: create-switch
create-switch: _opam/.opam-switch/switch-config

#   Force an update since 'opam switch create' only updates when it newly registers the repository.
#	Upsert (remove + add) FLEXLINKFLAGS on MSVC for debugging
_opam/.opam-switch/switch-config:
	opam switch create . --empty --repos diskuv=git+https://github.com/diskuv/diskuv-opam-repository.git#main,default=https://opam.ocaml.org
	opam update diskuv
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  if [ -n "$${COMSPEC:-}" ]; then opam option 'setenv-=FLEXLINKFLAGS+=" -link /DEBUG:FULL"'; fi
	  if [ -n "$${COMSPEC:-}" ]; then opam option 'setenv+=FLEXLINKFLAGS+=" -link /DEBUG:FULL"'; fi

.PHONY: install
install: create-switch
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam pin ocaml -k version 4.14.2 --no-action --yes && \
	  rm -rf _opam/src-ocaml && \
	  opam install $(OPTION_PACKAGES) ./ocaml.opam ./dkml-base-compiler.opam --keep-build-dir --yes

.PHONY: local-install
local-install: create-switch
	OPAMSWITCH="$$PWD" && \
	  if [ -x /usr/bin/cygpath ]; then OPAMSWITCH=$$(/usr/bin/cygpath -aw "$$OPAMSWITCH"); fi && \
	  opam pin ocaml -k version 4.14.2 --no-action --yes && \
	  rm -rf dkmldir Brewfile _opam/src-ocaml && \
	  opam install $(OPTION_PACKAGES) ./ocaml.opam ./dkml-base-compiler.opam --inplace-build --keep-build-dir --yes
