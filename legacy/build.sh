#!/usr/bin/env bash
#
# Build every example in src/ into a self-contained HTML page under build/.
#
# Each src/<Name>.elm is a `port module` that builds a Vega spec with elm-vega and
# sends it out the `elmToJS` port. We compile it to JavaScript with the elm-lang CLI
# (`elm make --project`), then wrap it in an HTML page that loads the Vega runtime
# from a CDN and renders the spec with vega-embed.
#
# The compiler is the elm-lang implementation in this monorepo. Point $ELM at it, e.g.
#   ELM="java -jar /path/to/elm.jar" ./build.sh
#   ELM=/path/to/elm-lang/elm.sh    ./build.sh
# It defaults to `elm` on your PATH.
#
set -euo pipefail
cd "$(dirname "$0")"

ELM="${ELM:-elm}"
OUT="build"
mkdir -p "$OUT"

echo "Building elm-vega examples with: $ELM"

shopt -s nullglob
for f in src/*.elm; do
  name="$(basename "$f" .elm)"
  echo "  • $name"
  $ELM make "$f" --project=elm.json -o "$OUT/$name.js" >/dev/null

  cat > "$OUT/$name.html" <<HTML
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>$name — elm-vega</title>
    <!-- Vega runtime + embed helper (Vega 5, matching the spec schema elm-vega emits) -->
    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    <style>
      body { font-family: system-ui, sans-serif; margin: 2rem; }
      a { color: #4682b4; }
    </style>
    <!-- The Elm-compiled program (a headless Platform.worker that emits the spec) -->
    <script src="$name.js"></script>
  </head>
  <body>
    <p><a href="index.html">← gallery</a></p>
    <h1>$name</h1>
    <div id="vis"></div>
    <!-- The compiled bundle hosts a worker; it pushes the spec(s) out the elmToJS port. -->
    <div id="app" style="display: none"></div>
    <script>
      window.\$app.ports.elmToJS.subscribe(function (namedSpecs) {
        var host = document.getElementById("vis");
        Object.keys(namedSpecs).forEach(function (name) {
          var el = document.createElement("div");
          host.appendChild(el);
          vegaEmbed(el, namedSpecs[name], { actions: true }).catch(console.warn);
        });
      });
    </script>
  </body>
</html>
HTML
done

# Gallery index linking every example.
{
  echo '<!DOCTYPE html>'
  echo '<html lang="en"><head><meta charset="utf-8"/><title>elm-vega examples</title>'
  echo '<style>body{font-family:system-ui,sans-serif;margin:2rem;max-width:42rem}li{margin:.3rem 0}</style>'
  echo '</head><body>'
  echo '<h1>elm-vega examples</h1>'
  echo '<p>Ten visualizations built with <code>gicentre/elm-vega</code>, compiled by the elm-lang CLI.</p>'
  echo '<ul>'
  for f in src/*.elm; do
    name="$(basename "$f" .elm)"
    echo "  <li><a href=\"$name.html\">$name</a></li>"
  done
  echo '</ul></body></html>'
} > "$OUT/index.html"

echo "Done. Open $OUT/index.html"
