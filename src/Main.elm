module Main exposing (main)

{-| A dynamic, in-browser editor for Vega-Lite charts written in Elm, built on the reusable `Editor`
shell. The left pane edits an Elm program written against the `VegaLite` module; it is interpreted
live in the browser and the resulting chart is drawn in the result pane (see `VegaPreview`).

The shell provides the IDE chrome — the file pane (the built-in example charts are its files; create
your own with the "+" button), code editing, resizable panes, sharing and autosave. This module just
supplies the Elm configuration (`Highlight`/`Assist`), the example files, the hidden `VegaLite`
library, and the Vega preview pane.
-}

import Assist
import Editor
import Examples
import Highlight
import VegaPreview
import WizardPanel


main : Program () (Editor.Model VegaPreview.Model VegaPreview.Msg) (Editor.Msg VegaPreview.Msg)
main =
    Editor.program
        { preview = VegaPreview.spec
        , intel = elmIntel
        , initialFiles = List.map (\ex -> ( ex.name, ex.code )) Examples.all
        , urls = []
        , libUrls = [ "VegaLite.elm" ]
        , title = "Elm · Vega-Lite editor"
        , tagline = "write Elm, see a chart — interpreted live in your browser"
        , sessionKey = "vega-examples.workspace"
        , fileBrowser = True
        , backLink = Nothing
        , panels = [ wizardPanel ]
        }


{-| The chart wizard as an alternative source pane: a form view of the selected file, switchable with
the code editor via the code pane's title-bar icons. -}
wizardPanel : Editor.Panel
wizardPanel =
    { icon = "wizard"
    , title = "Wizard"
    , tabs = []
    , view = WizardPanel.view
    }


{-| Elm code intelligence wired into the shell's code pane: syntax highlighting, identifier
autocomplete, and locating an interpreter error back in the source. -}
elmIntel : Editor.CodeIntel
elmIntel =
    { highlight = Highlight.segments
    , completions = \source caret -> Assist.completions source (Assist.wordAt source caret)
    , accept = Assist.accept
    , locate = \source message -> Maybe.andThen (Assist.squiggleFor source) (Assist.errorName message)
    }
