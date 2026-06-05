# elm-vega examples

Ten self-contained data visualizations built with
[`gicentre/elm-vega`](https://package.elm-lang.org/packages/gicentre/elm-vega/latest/)
and compiled with the [elm-lang](https://github.com/tunguski/elm-lang) implementation
of Elm (a from-scratch Elm compiler/interpreter in Java).

Each module is a headless `Platform.worker` that builds a [Vega](https://vega.github.io/vega/)
specification declaratively in Elm and sends it out the `elmToJS` port as JSON. An HTML
page loads the Vega runtime and renders the spec with
[vega-embed](https://github.com/vega/vega-embed).

## The examples

| Module | Chart |
|---|---|
| [`BarChart`](src/BarChart.elm) | Vertical bar chart with a hover highlight |
| [`HorizontalBarChart`](src/HorizontalBarChart.elm) | Horizontal bars with value labels |
| [`StackedBarChart`](src/StackedBarChart.elm) | Stacked bars (Vega `stack` transform) |
| [`GroupedBarChart`](src/GroupedBarChart.elm) | Clustered bars (faceted nested groups) |
| [`LineChart`](src/LineChart.elm) | Multi-series line chart (faceting) |
| [`AreaChart`](src/AreaChart.elm) | Filled area chart |
| [`ScatterPlot`](src/ScatterPlot.elm) | Scatterplot with size-encoded points |
| [`PieChart`](src/PieChart.elm) | Pie chart (Vega `pie` transform + `arc`) |
| [`DonutChart`](src/DonutChart.elm) | Donut chart (arc with inner radius) |
| [`Heatmap`](src/Heatmap.elm) | Grid heatmap with a sequential colour scale |

All examples use **inline data**, so they render offline with no data fetches.

## Building

You need the elm-lang CLI (this repo's sibling Elm implementation). Point `ELM` at it
and run the build script — it compiles every `src/*.elm` to `build/<Name>.js` and writes
an HTML page per example plus a `build/index.html` gallery.

```sh
# Unix / Git Bash
ELM=/path/to/elm-lang/elm.sh ./build.sh
# or
ELM="java -jar /path/to/elm.jar" ./build.sh
```

```powershell
# Windows PowerShell
$env:ELM = 'java -jar C:\path\to\elm.jar'; ./build.ps1
```

Then open `build/index.html` in a browser.

### What `build.sh` runs per example

```sh
elm make src/BarChart.elm --project=elm.json -o build/BarChart.js
```

`--project` makes the compiler load the project's `elm.json` dependencies — including
`gicentre/elm-vega` — from the package cache alongside the local source.

## How the wiring works

The elm-lang JS backend compiles the worker into a bundle that starts itself and exposes
its ports on `window.$app`. The host page subscribes and renders:

```js
window.$app.ports.elmToJS.subscribe(function (namedSpecs) {
  Object.keys(namedSpecs).forEach(function (name) {
    vegaEmbed("#vis", namedSpecs[name], { actions: true });
  });
});
```

(The official Elm compiler exposes `Elm.Main.init().ports.…` instead; the spec-building
Elm code is identical either way.)

## Dependencies

Added with the elm-lang package manager:

```sh
elm install gicentre/elm-vega --elm
```

See [`elm.json`](elm.json) for the resolved dependency set.
