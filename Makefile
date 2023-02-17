#!/usr/bin/env make
#
# vread.sh - read from stdin and validate the input
#
# By: Landon Curt Noll, 2004-2015, 2019, 2020, 2023
#     http://www.isthe.com/chongo
#
# This work is licensed under the Creative Commons
# Attribution-ShareAlike 4.0 International License.
# To view a copy of this license, visit
# http://creativecommons.org/licenses/by-sa/4.0/.
#
# This means you are free to:
#
# Share — copy and redistribute the material in any medium or format
#
# Adapt — remix, transform, and build upon the material for any purpose,
# even commercially.
#
# The licensor cannot revoke these freedoms as long as you follow the license terms.
#
# Under the following terms:
#
# Attribution — You must give appropriate credit, provide a link to
# the license, and indicate if changes were made. You may do so in any
# reasonable manner, but not in any way that suggests the licensor endorses
# you or your use.
#
# ShareAlike — If you remix, transform, or build upon the material, you
# must distribute your contributions under the same license as the original.
#
# No additional restrictions — You may not apply legal terms or
# technological measures that legally restrict others from doing anything
# the license permits.
#
# Share and enjoy! :-)


SHELL= bash
RM= rm
CP= cp
CHMOD= chmod

INSTALL= install

DESTDIR= /usr/local/bin

TARGETS= vread testvread

all: ${TARGETS}

vread: vread.sh
	${RM} -f $@
	${CP} -f $? $@
	${CHMOD} 0555 $@

testvread: testvread.sh
	${RM} -f $@
	${CP} -f $? $@
	${CHMOD} 0555 $@

configure:
	@echo nothing to configure

clean quick_clean quick_distclean distclean:

clobber quick_clobber: clean
	${RM} -f ${TARGETS}

install: all
	${INSTALL} -m 0555 ${TARGETS} ${DESTDIR}
