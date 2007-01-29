:
# striped down from /etc/rc_d/os.sh

# RCSid:
#	$Id: machine.sh,v 19.0 2003/07/16 05:15:44 aips2adm Exp $
#
#	@(#) Copyright (c) 1994 Simon J. Gerraty
#
#	This file is provided in the hope that it will
#	be of use.  There is absolutely NO WARRANTY.
#	Permission to copy, redistribute or otherwise
#	use this file is hereby granted provided that 
#	the above copyright notice and this notice are
#	left intact. 
#      
#	Please send copies of changes and bug-fixes to:
#	sjg@quick.com.au
#

OS=`uname`
OSREL=`uname -r`
#OSMAJOR=`IFS=.; set $OSREL; echo $1`
machine=`uname -m`
MACHINE=

# Great! Solaris keeps moving arch(1)
# we need this here, and it is not always available...
Which() {
	for d in `IFS=:; echo ${2:-$PATH}`
	do
		test -x $d/$1 && { echo $d/$1; break; }
	done
}

arch=`Which arch /usr/bin:/usr/ucb:$PATH`
test "$arch" && ARCH=`$arch`

case $OS in
*BSD)
	MACHINE=$OS.$machine
	;;
SunOS)
	case "$OSREL" in
	4.0*)	MACHINE=$ARCH;;
	5*)
                case "$machine" in
		sun4*)	MACHINE=solaris;;
		*)	MACHINE=solaris.$machine;;
		esac
                ;;
	esac
	;;
HP-UX)
	ARCH=`IFS="/-."; set $machine; echo $1`
	;;
IRIX)
	ARCH=`uname -p 2>/dev/null`
	;;
esac

MACHINE=${MACHINE:-$OS}
ARCH=${ARCH:-$machine}
MACHINE_ARCH=${MACHINE_ARCH:-$ARCH}

(
case "$0" in
arch*)	echo $ARCH;;
*)
	case "$1" in
	"")	echo $MACHINE;;
	*)	echo $MACHINE_ARCH;;
	esac
	;;
esac
) | tr 'A-Z' 'a-z'
