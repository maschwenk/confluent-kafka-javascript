#!/bin/sh
# Run only the self-contained static lib target from mklove/Makefile.base,
# with an input archive under an '@' path, using whatever sh/mktemp/ln the
# image provides.
set -e
R=/x/node_modules/@scope/pkg/rdk
mkdir -p $R/mklove $R/src $R/deps
cp /mk/Makefile.base $R/mklove/Makefile.base
cd $R/deps && echo 'int b(void){return 2;}' > b.c && cc -c b.c && ar rcs libdep.a b.o
cd $R/src && echo 'int a(void){return 1;}' > a.c
cat > Makefile <<MK
MKLOVE_DIR=$R/mklove/
LIBNAME=libtest
OBJS=a.o
MKL_STATIC_LIBS=$R/deps/libdep.a
HAS_GNU_AR=y
STRIP=strip
RANLIB=ranlib
include $R/mklove/Makefile.base
MK
readlink -f "$(command -v mktemp)" "$(command -v ln)" "$(command -v sh)" | tr '\n' ' '; echo
make -s libtest-static.a && echo "members: $(ar t libtest-static.a | tr '\n' ' ')"
ls -d arstatic* 2>/dev/null && echo "LEFTOVER TEMP FILES" || echo "no leftover temp files"
