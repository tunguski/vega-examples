# Build every example in src/ into a self-contained HTML page under build/ (Windows).
#
# Each src/<Name>.elm builds a Vega spec with elm-vega and sends it out the elmToJS
# port. We compile it with the elm-lang CLI, then wrap it in an HTML page that renders
# the spec with vega-embed from a CDN.
#
# Point $env:ELM at the elm-lang CLI, e.g.
#   $env:ELM = 'java -jar C:\path\to\elm.jar'; ./build.ps1
# Defaults to `elm` on PATH.

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$Elm = if ($env:ELM) { $env:ELM } else { 'elm' }
$Out = 'build'
New-Item -ItemType Directory -Force -Path $Out | Out-Null

Write-Host "Building elm-vega examples with: $Elm"

$names = @()
foreach ($f in Get-ChildItem src/*.elm) {
  $name = $f.BaseName
  $names += $name
  Write-Host "  * $name"
  & cmd /c "$Elm make `"$($f.FullName)`" --project=elm.json -o `"$Out/$name.js`"" | Out-Null

  $html = @"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>$name — elm-vega</title>
    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    <style>body { font-family: system-ui, sans-serif; margin: 2rem; } a { color: #4682b4; }</style>
    <script src="$name.js"></script>
  </head>
  <body>
    <p><a href="index.html">&larr; gallery</a></p>
    <h1>$name</h1>
    <div id="vis"></div>
    <div id="app" style="display: none"></div>
    <script>
      window.`$app.ports.elmToJS.subscribe(function (namedSpecs) {
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
"@
  Set-Content -Path "$Out/$name.html" -Value $html -Encoding utf8
}

$items = ($names | ForEach-Object { "  <li><a href=`"$_`.html`">$_</a></li>" }) -join "`n"
$index = @"
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/><title>elm-vega examples</title>
<style>body{font-family:system-ui,sans-serif;margin:2rem;max-width:42rem}li{margin:.3rem 0}</style>
</head><body>
<h1>elm-vega examples</h1>
<p>Ten visualizations built with <code>gicentre/elm-vega</code>, compiled by the elm-lang CLI.</p>
<ul>
$items
</ul></body></html>
"@
Set-Content -Path "$Out/index.html" -Value $index -Encoding utf8

Write-Host "Done. Open $Out/index.html"
