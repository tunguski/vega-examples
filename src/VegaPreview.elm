port module VegaPreview exposing (Model, Msg, spec)

{-| The result pane for the Elm · Vega-Lite editor, plugged into the reusable `Editor` shell as a
`Preview.Spec`. It interprets the selected file's `main` against the `VegaLite` library (a hidden lib
the shell fetches into scope) with the in-browser interpreter, encodes the resulting `Spec` to
Vega-Lite JSON (`EvalJson.jsonEncode`), and pushes it out the `renderSpec` port — the host page draws
it with vega-embed into the `#vis` element. On an interpreter error the last good chart is kept and
the error is reported back to the shell (which squiggles it in the code pane).

The chart wizard is not here — it is a source pane (`WizardPanel`) the shell shows beside the code
editor, so this module is purely the result view.
-}

import Eval
import Eval.Json
import Html exposing (Html, div)
import Html.Attributes exposing (id)
import Html.Lazy
import Preview exposing (Context)


{-| The preview's own state: the current interpreter error, if any. -}
type alias Model =
    { error : Maybe String }


{-| The preview has no interactive controls of its own. -}
type Msg
    = NoOp


{-| Outgoing: a Vega-Lite JSON spec to render (the host page hands it to vega-embed). -}
port renderSpec : String -> Cmd msg


{-| The pluggable preview the Vega editor wires into `Editor.program`. -}
spec : Preview.Spec Model Msg
spec =
    { init = \ctx -> render ctx { error = Nothing }
    , sourcesChanged = \ctx model -> render ctx model
    , update = \_ _ model -> ( model, Cmd.none )
    , subscriptions = \_ _ -> Sub.none
    , view = view
    , error = .error
    , onAddFile = Nothing
    , takeNewFile = \_ -> Nothing
    }


{-| Interpret the selected program against the VegaLite library and render it (or record the error,
keeping the last good chart on screen). -}
render : Context -> Model -> ( Model, Cmd Msg )
render ctx model =
    case Eval.mainValue (evalFiles ctx) of
        Ok value ->
            ( { model | error = Nothing }, renderSpec (Eval.Json.jsonEncode value) )

        Err e ->
            ( { model | error = Just e }, Cmd.none )


{-| The file set the interpreter evaluates: the selected file first, then the hidden library modules
(VegaLite.elm), which define the `toVegaLite`/encoding functions the program imports. -}
evalFiles : Context -> List ( String, String )
evalFiles ctx =
    ( ctx.selected, lookup ctx.selected ctx.files |> Maybe.withDefault "" ) :: ctx.libs


{-| The vega-embed target. Wrapped in a constant `lazy` so the shell's re-renders never re-diff it —
the SVG chart vega-embed injects into `#vis` survives every keystroke. -}
view : Context -> Model -> Html Msg
view _ _ =
    Html.Lazy.lazy visPane 0


visPane : Int -> Html Msg
visPane _ =
    div [ id "vega-preview" ] [ div [ id "vis" ] [] ]


lookup : String -> List ( String, String ) -> Maybe String
lookup name files =
    case files of
        ( n, content ) :: rest ->
            if n == name then
                Just content

            else
                lookup name rest

        [] ->
            Nothing
