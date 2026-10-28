#!/bin/sh
# Build librdkafka's self-contained static lib from a path containing '@',
# first with master's Makefile.base, then with the patched one.
set -u
D=/w/node_modules/@confluentinc/kafka-javascript/deps/librdkafka
mkdir -p "$D" && cp -a /src/. "$D/" && cd "$D" || exit 2
rm -rf .git
cp /orig/Makefile.base mklove/Makefile.base
./configure --install-deps --source-deps-only --disable-lz4-ext --enable-static --enable-strip --disable-gssapi --prefix=/w/out --libdir=/w/out > /w/configure.log 2>&1 || { tail -20 /w/configure.log; exit 3; }
echo "=== BEFORE (master Makefile.base)"
make -j"$(nproc)" libs > /w/before.log 2>&1; before=$?; echo "make exit=$before"
grep -n -A3 'Creating self-contained static library' /w/before.log | head -20
ls -la src/librdkafka-static.a 2>&1
rm -rf src/arstatic*
echo "=== AFTER (patched Makefile.base)"
cp /patched/Makefile.base mklove/Makefile.base
make -j"$(nproc)" libs > /w/after.log 2>&1; after=$?; echo "make exit=$after"
grep -n -A8 'Creating self-contained static library' /w/after.log | head -20
ls -la src/librdkafka-static.a
echo "=== member check"
libs=$(printf 'include Makefile.config\nprint:\n\t@echo $(MKL_STATIC_LIBS)\n' | make -s -f - print)
echo "inputs: src/librdkafka.a $libs"
for l in src/librdkafka.a $libs; do ar t "$l"; done | sort > /w/expected
ar t src/librdkafka-static.a | sort > /w/got
echo "expected members: $(wc -l < /w/expected), got: $(wc -l < /w/got)"
cmp -s /w/expected /w/got && echo "MEMBERS MATCH" || { echo "MEMBER MISMATCH"; diff /w/expected /w/got | head; }
ls -d src/arstatic* 2>/dev/null && echo "LEFTOVER TEMP FILES" || echo "no leftover temp files"
[ "$before" -ne 0 ] && grep -q 'Syntax error in archive script' /w/before.log || { echo "FAIL: master did not fail at the ar step"; exit 1; }
[ "$after" -eq 0 ] || { tail -30 /w/after.log; echo "FAIL: patched build failed"; exit 1; }
cmp -s /w/expected /w/got || exit 1
! ls -d src/arstatic* > /dev/null 2>&1 || exit 1
echo PASS
