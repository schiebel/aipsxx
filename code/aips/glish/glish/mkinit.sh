#! /bin/sh

cat <<!
// File created from glish.init via mkinit.sh.

extern const char* glish_init[];

const char* glish_init[] = {
!

sed -e 's/^\#.*//'			\
    -e 's/^[\ \	]*//'			\
    -e 's/[ 	][ 	]*/ /g'	\
    -e '/^$/d'				\
    -e 's/\\/&&/g'			\
    -e 's/"/\\"/g'			\
    -e 's/.*/  "&",/' $*

cat <<!
  0
};
!
