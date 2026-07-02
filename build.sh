#!/usr/bin/env bash
#
# build.sh — build the Elm · Vega-Lite editor.
#
# The app reuses the elm-lang in-browser interpreter (the whole elm-editor source tree — the Eval
# engine plus the shell). It is a source dependency declared in elm.vendored.json (the compiler pulls
# every module except its `Main` — collides with ours — and `ElmPreview` — replaced by VegaPreview,
# via the manifest's `exclude`), resolved at build time into git-deps/ or from the local checkout in
# elm.vendored.local.json. Set ELM to the elm-lang CLI (default `elm`).
#
#   ELM=../../elm.sh ./build.sh
#
set -euo pipefail
cd "$(dirname "$0")"

ELM="${ELM:-elm}"
OUT="build"

# Compile the app (it type-checks cleanly, like the other elm-lang example apps).
mkdir -p "$OUT"
echo "Compiling the editor app with: $ELM"
$ELM make src/Main.elm --project=elm.json -o "$OUT/app.js" >/dev/null

# 3) The VegaLite library source is fetched by the app at runtime and fed to the interpreter.
cp src/VegaLite.elm "$OUT/VegaLite.elm"

# 4) The editor shell's stylesheet (the .ed-* IDE chrome the host page layers its preview styles on).
cp "$EDITOR/editor.css" "$OUT/editor.css"

# 5) The host page (CDN vega + vega-embed, editor shell CSS + overlay, the compiled app, the ports).
cp index.template.html "$OUT/index.html"

echo "Done. Serve with:  npx --yes serve $OUT   (then open the printed URL)"
