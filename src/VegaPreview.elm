port module VegaPreview exposing (Model, Msg, spec)

{-| The result pane for the Elm · Vega-Lite editor, plugged into the reusable `Editor` shell as a
`Preview.Spec`. It interprets the selected file's `main` against the `VegaLite` library (a hidden lib
the shell fetches into scope) with the in-browser interpreter, encodes the resulting `Spec` to
Vega-Lite JSON (`EvalJson.jsonEncode`), and pushes it out the `renderSpec` port — the host page draws
it with vega-embed into the `#vis` element. On an interpreter error the last good chart is kept and
the error is reported back to the shell (which squiggles it in the code pane).

It also owns the **new-chart wizard**: the shell delegates its file-pane "+" button here
(`onAddFile = Just OpenWizard`), the wizard collects a (required, unique) module name + chart type +
CSV + field mapping, and on "Create" it generates an Elm module and hands it back to the shell to add
as a file (`takeNewFile`).
-}

import Eval
import EvalJson
import Html exposing (Html, button, div, h1, input, option, select, text, textarea)
import Html.Attributes exposing (class, disabled, id, placeholder, rows, selected, value)
import Html.Events exposing (on, onClick, onInput)
import Html.Lazy
import Json.Decode as Decode
import Preview exposing (Context)
import Wizard


{-| The preview's state: the current interpreter error, the open wizard form (if any), and a one-shot
slot holding a just-created file for the shell to pick up via `takeNewFile`. -}
type alias Model =
    { error : Maybe String
    , wizard : Maybe Wizard.Form
    , pending : Maybe ( String, String )
    }


type Msg
    = OpenWizard
    | CloseWizard
    | SetWizard Wizard.Form
    | CreateFromWizard


{-| Outgoing: a Vega-Lite JSON spec to render (the host page hands it to vega-embed). -}
port renderSpec : String -> Cmd msg


{-| The pluggable preview the Vega editor wires into `Editor.program`. -}
spec : Preview.Spec Model Msg
spec =
    { init = \ctx -> render ctx { error = Nothing, wizard = Nothing, pending = Nothing }
    , sourcesChanged = \ctx model -> render ctx model
    , update = update
    , subscriptions = \_ _ -> Sub.none
    , view = view
    , error = .error
    , onAddFile = Just OpenWizard
    , takeNewFile = takeNewFile
    }


update : Context -> Msg -> Model -> ( Model, Cmd Msg )
update ctx msg model =
    case msg of
        OpenWizard ->
            ( { model | wizard = Just Wizard.default }, Cmd.none )

        CloseWizard ->
            ( { model | wizard = Nothing }, Cmd.none )

        SetWizard form ->
            ( { model | wizard = Just form }, Cmd.none )

        CreateFromWizard ->
            case model.wizard of
                Just form ->
                    case nameError ctx form of
                        Just _ ->
                            -- Invalid name: keep the wizard open (the message is shown in the modal).
                            ( model, Cmd.none )

                        Nothing ->
                            ( { model
                                | wizard = Nothing
                                , pending = Just ( String.trim form.name, Wizard.generate form )
                              }
                            , Cmd.none
                            )

                Nothing ->
                    ( model, Cmd.none )


{-| The shell polls this after each update: hand it the just-created file once, clearing the slot. -}
takeNewFile : Model -> Maybe ( ( String, String ), Model )
takeNewFile model =
    Maybe.map (\file -> ( file, { model | pending = Nothing } )) model.pending


{-| Validates the wizard's module name: required, and not already a file in the editor. -}
nameError : Context -> Wizard.Form -> Maybe String
nameError ctx form =
    let
        name =
            String.trim form.name
    in
    if name == "" then
        Just "Please enter a module name."

    else if List.any (\( n, _ ) -> n == name) ctx.files then
        Just ("A file named \"" ++ name ++ "\" already exists.")

    else
        Nothing


{-| Interpret the selected program against the VegaLite library and render it (or record the error,
keeping the last good chart on screen). Wizard/pending state is preserved. -}
render : Context -> Model -> ( Model, Cmd Msg )
render ctx model =
    case Eval.mainValue (evalFiles ctx) of
        Ok value ->
            ( { model | error = Nothing }, renderSpec (EvalJson.jsonEncode value) )

        Err e ->
            ( { model | error = Just e }, Cmd.none )


{-| The file set the interpreter evaluates: the selected file first, then the hidden library modules
(VegaLite.elm), which define the `toVegaLite`/encoding functions the program imports. -}
evalFiles : Context -> List ( String, String )
evalFiles ctx =
    ( ctx.selected, lookup ctx.selected ctx.files |> Maybe.withDefault "" ) :: ctx.libs



-- VIEW


{-| The result column: the (lazy, never re-diffed) chart pane, plus the wizard modal when open. -}
view : Context -> Model -> Html Msg
view ctx model =
    div [ class "vega-result" ]
        [ Html.Lazy.lazy visPane 0
        , case model.wizard of
            Just form ->
                viewWizard ctx form

            Nothing ->
                text ""
        ]


{-| The vega-embed target. Wrapped in a constant `lazy` so the shell's re-renders never re-diff it —
the SVG chart vega-embed injects into `#vis` survives every keystroke. -}
visPane : Int -> Html Msg
visPane _ =
    div [ id "vega-preview" ] [ div [ id "vis" ] [] ]


viewWizard : Context -> Wizard.Form -> Html Msg
viewWizard ctx form =
    let
        err =
            nameError ctx form

        cols =
            Wizard.headers form.csv
    in
    div [ class "wiz-backdrop" ]
        [ div [ class "wiz-modal" ]
            [ h1 [] [ text "New chart" ]
            , field "Module name"
                (input
                    [ class "wiz-input"
                    , placeholder "e.g. SalesByMonth"
                    , value form.name
                    , onInput (\v -> SetWizard { form | name = v })
                    ]
                    []
                )
            , case err of
                Just message ->
                    div [ class "wiz-error" ] [ text message ]

                Nothing ->
                    text ""
            , field "Chart type"
                (selectInput Wizard.markChoices form.mark (\v -> SetWizard { form | mark = v }))
            , field "Data (CSV)"
                (textarea
                    [ class "wiz-csv", rows 6, value form.csv, onInput (\v -> SetWizard { form | csv = v }) ]
                    []
                )
            , field "X axis"
                (twin
                    (selectInput cols form.xField (\v -> SetWizard { form | xField = v }))
                    (selectInput Wizard.typeChoices form.xType (\v -> SetWizard { form | xType = v }))
                )
            , field "Y axis"
                (twin
                    (selectInput cols form.yField (\v -> SetWizard { form | yField = v }))
                    (selectInput Wizard.typeChoices form.yType (\v -> SetWizard { form | yType = v }))
                )
            , field "Colour by"
                (selectInput ("" :: cols) form.color (\v -> SetWizard { form | color = v }))
            , div [ class "wiz-actions" ]
                [ button [ onClick CloseWizard ] [ text "Cancel" ]
                , button [ class "wiz-primary", disabled (err /= Nothing), onClick CreateFromWizard ]
                    [ text "Create" ]
                ]
            ]
        ]


field : String -> Html Msg -> Html Msg
field labelText control =
    div [ class "wiz-field" ]
        [ div [ class "wiz-field-label" ] [ text labelText ]
        , control
        ]


twin : Html Msg -> Html Msg -> Html Msg
twin a b =
    div [ class "wiz-twin" ] [ a, b ]


selectInput : List String -> String -> (String -> Msg) -> Html Msg
selectInput choices current toMsg =
    select [ class "wiz-input", onChange toMsg ]
        (List.map
            (\c ->
                option [ value c, selected (c == current) ]
                    [ text
                        (if c == "" then
                            "(none)"

                         else
                            c
                        )
                    ]
            )
            choices
        )


onChange : (String -> Msg) -> Html.Attribute Msg
onChange toMsg =
    on "change" (Decode.map toMsg (Decode.at [ "target", "value" ] Decode.string))


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
