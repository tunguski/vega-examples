port module Main exposing (main)

{-| A dynamic, in-browser editor for Vega-Lite charts written in Elm.

The left pane is an Elm program written against the `VegaLite` module. It is evaluated **live in
the browser** by the elm-lang in-browser interpreter (the same engine as the elm-editor project):
`Eval.mainValue` runs the program's `main` to a `Spec` value and `EvalJson.jsonEncode` serialises
it to a Vega-Lite JSON spec, which is sent out the `renderSpec` port and drawn by vega-embed.

No server, no recompilation: editing the code re-interprets it on every keystroke.
-}

import Browser
import CodeEditor
import EvalJson
import Eval
import Examples exposing (Example)
import Highlight
import Html exposing (Html, button, div, h1, input, option, select, span, text, textarea)
import Html.Attributes exposing (class, classList, disabled, id, placeholder, rows, selected, value)
import Html.Events exposing (on, onClick, onInput)
import Html.Lazy exposing (lazy)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Storage
import Wizard


{-| localStorage key under which the workspace modules are persisted across reloads. -}
storageKey : String
storageKey =
    "vega-examples.workspace"


{-| Outgoing: a Vega-Lite JSON spec to render (empty string clears the view). -}
port renderSpec : String -> Cmd msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


{-| What the editor is currently bound to. Editing an example is transient (a scratch copy); editing
a workspace module writes back to it. -}
type Selection
    = SelExample String
    | SelWorkspace String


type alias Model =
    { code : String
    , caret : Int -- caret offset, for the code editor's current-line gutter highlight
    , lib : Maybe String -- the VegaLite.elm source, fetched at startup (fed to the interpreter)
    , error : Maybe String
    , selected : Selection
    , workspace : List Example -- user-created modules, in memory for this browser session
    , wizard : Maybe Wizard.Form
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { code = Examples.starter
      , caret = 0
      , lib = Nothing
      , error = Nothing
      , selected = SelExample "Bar chart"
      , workspace = []
      , wizard = Nothing
      }
    , Cmd.batch
        [ Http.get { url = "VegaLite.elm", expect = Http.expectString LibLoaded }
        , Storage.load storageKey LoadedWorkspace
        ]
    )



-- UPDATE


type Msg
    = CodeChanged String Int
    | LibLoaded (Result Http.Error String)
    | LoadedWorkspace (Maybe String)
    | PickExample Example
    | PickWorkspace Example
    | OpenWizard
    | CloseWizard
    | SetWizard Wizard.Form
    | CreateFromWizard


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CodeChanged code caret ->
            -- Edits to a workspace module are written back to it (and persisted); editing an example
            -- is transient.
            let
                updated =
                    { model | code = code, caret = caret, workspace = writeBack model.selected code model.workspace }

                ( rendered, renderCmd ) =
                    compile updated
            in
            ( rendered, withSave model.selected rendered renderCmd )

        LibLoaded (Ok lib) ->
            compile { model | lib = Just lib }

        LoadedWorkspace stored ->
            case stored of
                Just json ->
                    ( { model | workspace = decodeWorkspace json }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        LibLoaded (Err _) ->
            ( { model | error = Just "Could not load VegaLite.elm (serve the project over HTTP)." }
            , Cmd.none
            )

        PickExample ex ->
            compile { model | code = ex.code, caret = 0, selected = SelExample ex.name }

        PickWorkspace m ->
            compile { model | code = m.code, caret = 0, selected = SelWorkspace m.name }

        OpenWizard ->
            ( { model | wizard = Just Wizard.default }, Cmd.none )

        CloseWizard ->
            ( { model | wizard = Nothing }, Cmd.none )

        SetWizard form ->
            ( { model | wizard = Just form }, Cmd.none )

        CreateFromWizard ->
            case model.wizard of
                Just form ->
                    case nameError model.workspace form of
                        Just _ ->
                            -- Invalid name: keep the wizard open (the message is shown in the modal).
                            ( model, Cmd.none )

                        Nothing ->
                            let
                                name =
                                    String.trim form.name

                                newModule =
                                    { name = name, code = Wizard.generate form }

                                ( rendered, renderCmd ) =
                                    compile
                                        { model
                                            | code = newModule.code
                                            , caret = 0
                                            , wizard = Nothing
                                            , selected = SelWorkspace name
                                            , workspace = model.workspace ++ [ newModule ]
                                        }
                            in
                            ( rendered, Cmd.batch [ renderCmd, persist rendered ] )

                Nothing ->
                    ( model, Cmd.none )


{-| When a workspace module is selected, persist the edited code back into the workspace list. -}
writeBack : Selection -> String -> List Example -> List Example
writeBack selection code workspace =
    case selection of
        SelWorkspace name ->
            List.map
                (\m ->
                    if m.name == name then
                        { m | code = code }

                    else
                        m
                )
                workspace

        SelExample _ ->
            workspace


{-| Validates the wizard's module name: required, and unique within the workspace. -}
nameError : List Example -> Wizard.Form -> Maybe String
nameError workspace form =
    let
        name =
            String.trim form.name
    in
    if name == "" then
        Just "Please enter a module name."

    else if List.any (\m -> m.name == name) workspace then
        Just ("A workspace module named \"" ++ name ++ "\" already exists.")

    else
        Nothing


{-| Interpret the current program against the VegaLite library and render (or record the error). -}
compile : Model -> ( Model, Cmd Msg )
compile model =
    case model.lib of
        Nothing ->
            ( model, Cmd.none )

        Just lib ->
            case Eval.mainValue [ ( "VegaLite.elm", lib ), ( "Main.elm", model.code ) ] of
                Ok spec ->
                    ( { model | error = Nothing }, renderSpec (EvalJson.jsonEncode spec) )

                Err e ->
                    ( { model | error = Just e }, Cmd.none )


{-| Batch a workspace save onto an existing command, but only when a workspace module is selected
(so transient edits to an example aren't persisted). -}
withSave : Selection -> Model -> Cmd Msg -> Cmd Msg
withSave selection model cmd =
    case selection of
        SelWorkspace _ ->
            Cmd.batch [ cmd, persist model ]

        SelExample _ ->
            cmd


persist : Model -> Cmd Msg
persist model =
    Storage.save storageKey (encodeWorkspace model.workspace)


encodeWorkspace : List Example -> String
encodeWorkspace workspace =
    Encode.encode 0
        (Encode.list
            (\m -> Encode.object [ ( "name", Encode.string m.name ), ( "code", Encode.string m.code ) ])
            workspace
        )


decodeWorkspace : String -> List Example
decodeWorkspace json =
    case Decode.decodeString (Decode.list moduleDecoder) json of
        Ok modules ->
            modules

        Err _ ->
            []


moduleDecoder : Decode.Decoder Example
moduleDecoder =
    Decode.map2 Example
        (Decode.field "name" Decode.string)
        (Decode.field "code" Decode.string)



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ viewHeader
        , div [ class "body" ]
            [ viewSidebar model
            , viewEditor model
            , lazy viewPreview 0
            ]
        , case model.wizard of
            Just form ->
                viewWizard model form

            Nothing ->
                text ""
        ]


viewHeader : Html Msg
viewHeader =
    div [ class "header" ]
        [ h1 [] [ text "Elm · Vega-Lite editor" ]
        , span [ class "tagline" ] [ text "write Elm, see a chart — interpreted live in your browser" ]
        , button [ class "primary", onClick OpenWizard ] [ text "+ New chart" ]
        ]


viewSidebar : Model -> Html Msg
viewSidebar model =
    div [ class "sidebar" ]
        [ div [ class "label" ] [ text "Examples" ]
        , div [ class "examples" ]
            (List.map (exampleButton model.selected) Examples.all)
        , div [ class "label workspace-label" ] [ text "Workspace" ]
        , div [ class "examples" ]
            (if List.isEmpty model.workspace then
                [ div [ class "empty" ] [ text "Use “+ New chart” to create a module." ] ]

             else
                List.map (workspaceButton model.selected) model.workspace
            )
        ]


exampleButton : Selection -> Example -> Html Msg
exampleButton selected ex =
    button
        [ classList [ ( "example", True ), ( "active", selected == SelExample ex.name ) ]
        , onClick (PickExample ex)
        ]
        [ text ex.name ]


workspaceButton : Selection -> Example -> Html Msg
workspaceButton selected m =
    button
        [ classList [ ( "example", True ), ( "active", selected == SelWorkspace m.name ) ]
        , onClick (PickWorkspace m)
        ]
        [ text m.name ]


viewEditor : Model -> Html Msg
viewEditor model =
    div [ class "editor" ]
        [ CodeEditor.view
            { source = model.code
            , caret = model.caret
            , highlight = Highlight.segments
            , onChange = CodeChanged
            }
        , case model.error of
            Just e ->
                div [ class "error" ] [ text e ]

            Nothing ->
                case model.lib of
                    Nothing ->
                        div [ class "status" ] [ text "Loading the VegaLite library…" ]

                    Just _ ->
                        div [ class "status ok" ] [ text "✓ rendered" ]
        ]


{-| Lazy + a constant argument so Elm reuses this node and never re-diffs its children — the
vega-embed DOM injected into `#vis` survives the app's re-renders. -}
viewPreview : Int -> Html Msg
viewPreview _ =
    div [ class "preview" ]
        [ div [ id "vis" ] [] ]



-- WIZARD VIEW


viewWizard : Model -> Wizard.Form -> Html Msg
viewWizard model form =
    let
        err =
            nameError model.workspace form
    in
    div [ class "modal-backdrop" ]
        [ div [ class "modal" ]
            [ h1 [] [ text "New chart" ]
            , field "Module name"
                (input
                    [ class "text-input"
                    , placeholder "e.g. SalesByMonth"
                    , value form.name
                    , onInput (\v -> SetWizard { form | name = v })
                    ]
                    []
                )
            , case err of
                Just message ->
                    div [ class "field-error" ] [ text message ]

                Nothing ->
                    text ""
            , field "Chart type"
                (selectInput Wizard.markChoices form.mark (\v -> SetWizard { form | mark = v }))
            , field "Data (CSV)"
                (textarea
                    [ class "csv", rows 6, value form.csv, onInput (\v -> SetWizard { form | csv = v }) ]
                    []
                )
            , let
                cols =
                    Wizard.headers form.csv
              in
              div []
                [ field "X axis"
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
                ]
            , div [ class "modal-actions" ]
                [ button [ onClick CloseWizard ] [ text "Cancel" ]
                , button [ class "primary", disabled (err /= Nothing), onClick CreateFromWizard ] [ text "Create" ]
                ]
            ]
        ]


field : String -> Html Msg -> Html Msg
field labelText control =
    div [ class "field" ]
        [ div [ class "field-label" ] [ text labelText ]
        , control
        ]


twin : Html Msg -> Html Msg -> Html Msg
twin a b =
    div [ class "twin" ] [ a, b ]


selectInput : List String -> String -> (String -> Msg) -> Html Msg
selectInput choices current toMsg =
    select [ onChange toMsg ]
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
