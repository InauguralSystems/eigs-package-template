#!/usr/bin/env bash
# Smoke tests for the package, run from CI and from a clean clone.
# Pattern: build a tiny consumer in a tmpdir whose eigs_modules/<name>/
# points at this repo, then `import <name>` and exercise the surface.
set -euo pipefail

EIGS="${EIGENSCRIPT:-eigenscript}"
PKG_NAME="$(python3 -c 'import json,sys;print(json.load(open("eigs.json"))["name"])')"
PKG_ROOT="$(pwd)"

TMP="$(mktemp -d)"
trap "rm -rf '$TMP'" EXIT

# Pretend a consumer has cloned this package into eigs_modules/<name>/.
mkdir -p "$TMP/eigs_modules/$PKG_NAME"
# Copy the package tree (just the .eigs files at root — packages don't
# vendor their own deps). cp -a preserves perms.
cp -a "$PKG_ROOT/$PKG_NAME.eigs" "$TMP/eigs_modules/$PKG_NAME/"
[ -f "$PKG_ROOT/eigs.json" ] && cp -a "$PKG_ROOT/eigs.json" "$TMP/eigs_modules/$PKG_NAME/"

cat > "$TMP/app.eigs" <<EOF
import $PKG_NAME
print of $PKG_NAME.greet of "world"
print of $PKG_NAME.VERSION
EOF

cd "$TMP"
OUT=$("$EIGS" app.eigs 2>&1)
if ! echo "$OUT" | grep -q "hello, world, from $PKG_NAME v"; then
    echo "FAIL: greet didn't render — got:"
    echo "$OUT"
    exit 1
fi
echo "PASS: import $PKG_NAME → greet round-trips"

# Private names (leading _) should not appear in the module's keys.
cat > "$TMP/app2.eigs" <<EOF
import $PKG_NAME
ks is keys of $PKG_NAME
if (contains of [ks, "_internal_marker"]) == 1:
    print of "LEAKED"
else:
    print of "private"
EOF
OUT2=$("$EIGS" "$TMP/app2.eigs" 2>&1)
if [ "$OUT2" != "private" ]; then
    echo "FAIL: _internal_marker should be private but appears in module keys"
    echo "$OUT2"
    exit 1
fi
echo "PASS: leading-underscore names stay private"
