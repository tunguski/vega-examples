module WizardPanel exposing (view)

{-| The Vega wizard as a **source pane** for the `Editor` shell (a `Panel`): a structured, form-based
alternative to the code editor for the same file. The shell shows it next to the "Code" view in the
code pane's title bar; switching between them is the shell's job.

The contract is `Int -> String -> Html String`: given the active tab (unused — one tab) and the file's
current source, render a form (parsed from that source with `Wizard.parse`) whose every change emits
the **regenerated full source** (`Wizard.generate`). The shell folds that back into the file — so the
form and the code stay two views of one program.

The basic chart controls are always visible; the chart frame and mark options live in a folded
"Advanced" `<details>` section at the bottom (its open/closed state lives in the DOM, so this stateless
panel needs no extra state). Controls emit on **change** (blur), so typing in a text field doesn't
regenerate — and reset the caret — on every keystroke.
-}

import Html exposing (Html, div, input, label, node, option, select, text, textarea)
import Html.Attributes exposing (checked, class, placeholder, rows, selected, type_, value)
import Html.Events exposing (on)
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
                [ class "wiz-input wiz-csv", rows 8, value form.csv, onEdit (\v -> { form | csv = v }) ]
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
        , advanced form
        ]


{-| The folded "Advanced" section: chart title, size and mark options. -}
advanced : Form -> Html String
advanced form =
    node "details"
        [ class "wiz-advanced" ]
        [ node "summary" [ class "wiz-summary" ] [ text "Advanced" ]
        , field "Title"
            (textField "Chart title" form.title (\v -> { form | title = v }))
        , field "Size (width × height)"
            (twin
                (textField "width" form.width (\v -> { form | width = v }))
                (textField "height" form.height (\v -> { form | height = v }))
            )
        , field "Mark options"
            (twin
                (checkboxField "Tooltip" form.tooltip (\b -> { form | tooltip = b }))
                (checkboxField "Point markers" form.point (\b -> { form | point = b }))
            )
        , field "Opacity (0–1)"
            (textField "1" form.opacity (\v -> { form | opacity = v }))
        , field "Interpolate (line/area)"
            (picker Wizard.interpolateChoices form.interpolate (\v -> { form | interpolate = v }))
        , field "Inner radius (donut)"
            (textField "0" form.innerRadius (\v -> { form | innerRadius = v }))
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
    select [ class "wiz-input", onEdit toForm ]
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


textField : String -> String -> (String -> Form) -> Html String
textField hint current toForm =
    input [ class "wiz-input", placeholder hint, value current, onEdit toForm ] []


checkboxField : String -> Bool -> (Bool -> Form) -> Html String
checkboxField labelText current toForm =
    label [ class "wiz-check" ]
        [ input [ type_ "checkbox", checked current, onCheck toForm ] []
        , text (" " ++ labelText)
        ]


{-| Emit the regenerated source from a control's new string value, on change (blur). -}
onEdit : (String -> Form) -> Html.Attribute String
onEdit toForm =
    on "change"
        (Decode.map (\v -> Wizard.generate (toForm v))
            (Decode.at [ "target", "value" ] Decode.string)
        )


onCheck : (Bool -> Form) -> Html.Attribute String
onCheck toForm =
    on "change"
        (Decode.map (\b -> Wizard.generate (toForm b))
            (Decode.at [ "target", "checked" ] Decode.bool)
        )
