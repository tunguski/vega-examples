# build.ps1 — build the Elm · Vega-Lite editor (Windows).
#
# The app reuses the elm-lang in-browser interpreter (elm-editor). Set EDITOR to the elm-editor
# checkout (default ..\elm-editor) and ELM to the elm-lang CLI (default `elm`).
#
#   $env:ELM = 'java -jar C:\path\to\elm.jar'; ./build.ps1

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$Elm = if ($env:ELM) { $env:ELM } else { 'elm' }
$Editor = if ($env:EDITOR) { $env:EDITOR } else { '..\elm-editor' }
$Out = 'build'

# 1) Vendor the whole elm-editor source tree (engine Eval + Eval/* submodules, plus the shell), minus
#    its own Main (collides with ours) and ElmPreview (replaced by VegaPreview). Copying the tree keeps
#    us robust to elm-editor module renames.
if (-not (Test-Path (Join-Path $Editor 'src/Editor.elm'))) {
  Write-Error "$Editor/src/Editor.elm not found - set EDITOR to the elm-editor checkout"
}
if (Test-Path vendor) { Remove-Item -Recurse -Force vendor }
Copy-Item -Recurse (Join-Path $Editor 'src') vendor
Remove-Item -Force vendor/Main.elm, vendor/ElmPreview.elm -ErrorAction SilentlyContinue

# 2) Compile the app (--no-check: the interpreter doesn't pass the strict type checker).
New-Item -ItemType Directory -Force -Path $Out | Out-Null
Write-Host "Compiling the editor app with: $Elm"
& cmd /c "$Elm make src/Main.elm --project=elm.json -o `"$Out/app.js`" --no-check" | Out-Null

# 3) The app fetches VegaLite.elm at runtime and feeds it to the interpreter.
Copy-Item src/VegaLite.elm "$Out/VegaLite.elm" -Force

# 4) The editor shell's stylesheet (the .ed-* IDE chrome the host page layers its preview styles on).
Copy-Item (Join-Path $Editor 'editor.css') "$Out/editor.css" -Force

# 5) The host page (CDN vega + vega-embed, the app, and the port wiring).
Copy-Item index.template.html "$Out/index.html" -Force

Write-Host "Done. Serve with:  npx --yes serve $Out"
