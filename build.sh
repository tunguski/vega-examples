#!/usr/bin/env bash
#
# build.sh — build the Elm · Vega-Lite editor.
#
# The app reuses the elm-lang in-browser interpreter (the elm-editor project). Since Elm has no
# cross-project imports, we copy the interpreter modules we need into vendor/ (a source-directory
# listed in elm.json) before compiling. Set EDITOR to the elm-editor checkout (default ../elm-editor)
# and ELM to the elm-lang CLI (default `elm`).
#
#   ELM=../../elm.sh ./build.sh
#
set -euo pipefail
cd "$(dirname "$0")"

ELM="${ELM:-elm}"
EDITOR="${EDITOR:-../elm-editor}"
OUT="build"

# 1) Vendor the interpreter modules from elm-editor (only the engine — not its UI/Main).
mkdir -p vendor
for m in Lang Lexer Parser EvalJson EvalPlayground EvalRender Eval Highlight CodeEditor; do
  if [ ! -f "$EDITOR/src/$m.elm" ]; then
    echo "build.sh: missing $EDITOR/src/$m.elm — set EDITOR to the elm-editor checkout" >&2
    exit 1
  fi
  cp "$EDITOR/src/$m.elm" "vendor/$m.elm"
done

# 2) Compile the app (the editor interpreter doesn't pass our strict type checker, so --no-check).
mkdir -p "$OUT"
echo "Compiling the editor app with: $ELM"
$ELM make src/Main.elm --project=elm.json -o "$OUT/app.js" --no-check >/dev/null

# 3) The VegaLite library source is fetched by the app at runtime and fed to the interpreter.
cp src/VegaLite.elm "$OUT/VegaLite.elm"

# 4) The host page (CDN vega + vega-embed, the compiled app, and the port wiring).
cp index.template.html "$OUT/index.html"

echo "Done. Serve with:  npx --yes serve $OUT   (then open the printed URL)"
