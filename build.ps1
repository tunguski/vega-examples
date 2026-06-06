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

# 1) Vendor the interpreter modules from elm-editor (only the engine).
New-Item -ItemType Directory -Force -Path vendor | Out-Null
foreach ($m in 'Lang','Lexer','Parser','EvalJson','EvalPlayground','EvalRender','Eval','Highlight') {
  $srcFile = Join-Path $Editor "src/$m.elm"
  if (-not (Test-Path $srcFile)) {
    Write-Error "missing $srcFile - set EDITOR to the elm-editor checkout"
  }
  Copy-Item $srcFile "vendor/$m.elm" -Force
}

# 2) Compile the app (--no-check: the interpreter doesn't pass the strict type checker).
New-Item -ItemType Directory -Force -Path $Out | Out-Null
Write-Host "Compiling the editor app with: $Elm"
& cmd /c "$Elm make src/Main.elm --project=elm.json -o `"$Out/app.js`" --no-check" | Out-Null

# 3) The app fetches VegaLite.elm at runtime and feeds it to the interpreter.
Copy-Item src/VegaLite.elm "$Out/VegaLite.elm" -Force

# 4) The host page (CDN vega + vega-embed, the app, and the port wiring).
Copy-Item index.template.html "$Out/index.html" -Force

Write-Host "Done. Serve with:  npx --yes serve $Out"
