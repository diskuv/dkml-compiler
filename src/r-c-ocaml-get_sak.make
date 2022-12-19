# runtime/Makefile creates a 'sak' executable and uses it as
# a support tool inside the Makefile. When cross-compiling
# we need 'sak' to be the host ABI always! The runtime/Makefile
# supports cross-compilers by letting you specify SAK_CC,
# SAK_CFLAGS and SAK_LINK, and they have default values that
# serve as templates for this makefile (sak-as-sh-vars).
#
# All that is needed is to inspect the host Makefile.config (with this
# make file) to generate SAK_CC, etc. that will be supplied to
# the mlcross cross-compiler.
#
# Call this makefile with the 1 and 2 makefile variables set. That is:
#   make -f get_sake.make sak.source.sh 1=__1__ 2=__2__

include Makefile

sak.source.sh: Makefile
	@printf "SAK_CC='$(CC)'\n" > $@
	@printf "SAK_CFLAGS='$(OC_CFLAGS) $(CFLAGS) $(OC_CPPFLAGS) $(CPPFLAGS)'\n" >> $@
	@printf "SAK_LINK='$(MKEXE_USING_COMPILER)'\n" | sed 's/__1__/$$\(1)/; s/__2__/$$\(2)/' >> $@
