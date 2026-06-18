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

# 1) Vendor the whole elm-editor source tree (the interpreter engine — Eval + its Eval/* submodules —
#    plus the shell: Editor/Preview/CodeEditor/Highlight/Assist/Share). Copying the tree keeps us
#    robust to elm-editor's module renames. We drop only its own `Main` (collides with ours) and
#    `ElmPreview` (the elm-lang result pane we replace with VegaPreview).
if [ ! -f "$EDITOR/src/Editor.elm" ]; then
  echo "build.sh: $EDITOR/src/Editor.elm not found — set EDITOR to the elm-editor checkout" >&2
  exit 1
fi
rm -rf vendor && mkdir -p vendor
cp -r "$EDITOR/src/." vendor/
rm -f vendor/Main.elm vendor/ElmPreview.elm

# 2) Compile the app (the editor interpreter doesn't pass our strict type checker, so --no-check).
mkdir -p "$OUT"
echo "Compiling the editor app with: $ELM"
$ELM make src/Main.elm --project=elm.json -o "$OUT/app.js" --no-check >/dev/null

# 3) The VegaLite library source is fetched by the app at runtime and fed to the interpreter.
cp src/VegaLite.elm "$OUT/VegaLite.elm"

# 4) The editor shell's stylesheet (the .ed-* IDE chrome the host page layers its preview styles on).
cp "$EDITOR/editor.css" "$OUT/editor.css"

# 5) The host page (CDN vega + vega-embed, editor shell CSS + overlay, the compiled app, the ports).
cp index.template.html "$OUT/index.html"

echo "Done. Serve with:  npx --yes serve $OUT   (then open the printed URL)"
