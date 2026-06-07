module WizardPanel exposing (view)

{-| The Vega wizard as a **source pane** for the `Editor` shell (a `Panel`): a structured, form-based
alternative to the code editor for the same file. The shell shows it next to the "Code" view in the
code pane's title bar; switching between them is the shell's job.

The contract is `Int -> String -> Html String`: given the active tab (unused — one tab) and the file's
current source, render a form (parsed from that source with `Wizard.parse`) whose every change emits
the **regenerated full source** (`Wizard.generate`). The shell folds that back into the file — so the
form and the code stay two views of one program.
-}

import Html exposing (Html, div, option, select, text, textarea)
import Html.Attributes exposing (class, rows, selected, value)
import Html.Events exposing (on, onInput)
import Json.Decode as Decode
import Wizard exposing (Form)


view : Int -> String -> Html String
view _ source =
    let
        form =
            Wizard.parse source

        cols =
            Wizard.headers form.csv
    in
    div [ class "wiz-panel" ]
        [ field "Chart type"
            (picker Wizard.markChoices form.mark (\v -> { form | mark = v }))
        , field "Data (CSV)"
            (textarea
                [ class "wiz-input wiz-csv"
                , rows 8
                , value form.csv
                , onInput (\v -> Wizard.generate { form | csv = v })
                ]
                []
            )
        , field "X axis"
            (twin
                (picker cols form.xField (\v -> { form | xField = v }))
                (picker Wizard.typeChoices form.xType (\v -> { form | xType = v }))
            )
        , field "Y axis"
            (twin
                (picker cols form.yField (\v -> { form | yField = v }))
                (picker Wizard.typeChoices form.yType (\v -> { form | yType = v }))
            )
        , field "Colour by"
            (picker ("" :: cols) form.color (\v -> { form | color = v }))
        ]


field : String -> Html String -> Html String
field labelText control =
    div [ class "wiz-field" ]
        [ div [ class "wiz-field-label" ] [ text labelText ]
        , control
        ]


twin : Html String -> Html String -> Html String
twin a b =
    div [ class "wiz-twin" ] [ a, b ]


{-| A `<select>` whose choice rebuilds the form (via `toForm`) and emits the regenerated source. -}
picker : List String -> String -> (String -> Form) -> Html String
picker choices current toForm =
    select [ class "wiz-input", onPick toForm ]
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


onPick : (String -> Form) -> Html.Attribute String
onPick toForm =
    on "change"
        (Decode.map (\v -> Wizard.generate (toForm v))
            (Decode.at [ "target", "value" ] Decode.string)
        )
