# vega-examples — a live, in-browser Vega-Lite editor written in Elm

A dynamic editor for [Vega-Lite](https://vega.github.io/vega-lite/) charts. You write **Elm** in the
left pane (against a compact `VegaLite` module); it is **interpreted live in your browser** and the
resulting Vega-Lite spec is drawn on the right by [vega-embed](https://github.com/vega/vega-embed).
No server, no recompilation — every keystroke re-renders the chart.

It is built on the [elm-lang](https://github.com/tunguski/elm-lang) ecosystem:

- The live evaluator is the **elm-editor** in-browser Elm interpreter
  ([github.com/tunguski/elm-editor](https://github.com/tunguski/elm-editor)) — `Eval.mainValue` runs
  the program's `main` to a `Spec` value and `EvalJson.jsonEncode` serialises it to Vega-Lite JSON.
- The whole app is itself an Elm `Browser.element` program, compiled to JavaScript by the elm-lang
  compiler.

## Features

- **Built on the elm-editor shell** (`Editor.program`) — a file browser, code editing with Elm
  syntax highlighting + autocomplete, resizable panes, sharing and autosaved sessions. Write Elm
  using the `VegaLite` API and the chart updates as you type.
- **Examples** — the file browser opens with ready-made charts: bar, grouped bar, line, area,
  scatter, bubble, pie, donut and histogram. Your own files are added alongside them and the whole
  session is autosaved, so it survives a reload.
- **Wizard source pane** — the code pane's title bar has a **Wizard** view next to **Code** (switch
  with the icons, like the bs-theme-builder's form panel). The wizard is a structured, two-way view
  of the *same* file: pick a chart type, edit the CSV, map columns to x / y / colour, and the Elm
  source regenerates; switch to Code and it round-trips back into the form (`Wizard.parse` ⇄
  `Wizard.generate`). A folded **Advanced** section adds the chart title, size and mark options
  (tooltip, point markers, opacity, interpolation, donut inner-radius).

## The `VegaLite` module

[`src/VegaLite.elm`](src/VegaLite.elm) is a compact, editor-interpretable subset of the Vega-Lite
grammar (in the spirit of [gicentre/elm-vegalite](https://package.elm-lang.org/packages/gicentre/elm-vegalite/latest/)),
built entirely on the `Json.Encode` operations the interpreter supports. A chart is just:

```elm
import VegaLite exposing (..)

main : Spec
main =
    toVegaLite
        [ title "Monthly sales"
        , dataFromColumns
            [ ( "month", strings [ "Jan", "Feb", "Mar", "Apr", "May" ] )
            , ( "sales", numbers [ 28, 55, 43, 91, 81 ] )
            ]
        , mark bar []
        , encoding
            [ pX "month" [ nominal ]
            , pY "sales" [ quantitative ]
            ]
        ]
```

## Build & run

You need the [elm-lang](https://github.com/tunguski/elm-lang) CLI and a checkout of
[elm-editor](https://github.com/tunguski/elm-editor) next to this project (the build copies the
interpreter modules from it, since Elm has no cross-project imports).

```sh
# from this directory; ELM points at the elm-lang CLI, EDITOR at the elm-editor checkout
ELM=../../elm.sh EDITOR=../elm-editor ./build.sh
npx --yes serve build      # then open the printed URL
```

```powershell
# Windows
$env:ELM = 'java -jar C:\path\to\elm.jar'; $env:EDITOR = '..\elm-editor'; ./build.ps1
```

`build.sh` copies the interpreter modules into `vendor/`, compiles `src/Main.elm` with the elm-lang
JS backend (`--no-check`, as the interpreter leans on idioms the strict checker doesn't fully
analyse), copies `VegaLite.elm` (the app fetches it at runtime to feed the interpreter), and writes
`build/index.html` (vega + vega-embed from a CDN, the app, and the port wiring).

## Layout

| Path | Role |
|---|---|
| [src/Main.elm](src/Main.elm) | The thin host: `Editor.program` wired with the Vega preview, the example files, the hidden `VegaLite` lib, and Elm code intelligence. |
| [src/VegaPreview.elm](src/VegaPreview.elm) | The result pane (`Preview.Spec`): interprets the selected file to a spec and pushes it out the `renderSpec` port. |
| [src/WizardPanel.elm](src/WizardPanel.elm) | The wizard **source pane** (an `Editor.Panel`): a form view of the file that emits the regenerated source on every change. |
| [src/Wizard.elm](src/Wizard.elm) | The wizard's pure core: `parse` (source → form) and `generate` (form → source), plus CSV handling. |
| [src/VegaLite.elm](src/VegaLite.elm) | The Vega-Lite library (fetched at runtime and fed to the interpreter). |
| [src/Examples.elm](src/Examples.elm) | The built-in example programs (the shell's initial files). |
| `vendor/` | elm-editor modules (interpreter engine + the `Editor` shell) copied at build time (git-ignored). |
| [legacy/](legacy/) | The original ten **full-grammar** `gicentre/elm-vega` examples + their static-gallery build scripts. |

## How it renders without an Elm/DOM clash

vega-embed injects its own SVG into `#vis`, which Elm's virtual DOM would otherwise wipe on the next
re-render. `VegaPreview` wraps the chart pane in `Html.Lazy.lazy` with a constant argument, so the
runtime reuses that node and never re-diffs its children — the chart survives every edit.
