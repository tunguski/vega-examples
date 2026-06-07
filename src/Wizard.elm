module Wizard exposing (Form, default, headers, generate, parse, markChoices, typeChoices, interpolateChoices)

{-| The chart wizard: a structured, two-way view of a Vega-Lite program. `generate` turns a chart
type + a small CSV dataset + a field mapping (and the optional "advanced" properties — title, size and
mark options) into an Elm program written against the `VegaLite` module; `parse` reads such a program
back into the form (best-effort, so switching the editor's Code ⇄ Wizard panes reflects the current
source). Pure helpers — the panel UI lives in `WizardPanel`.
-}


type alias Form =
    { mark : String
    , csv : String
    , xField : String
    , xType : String
    , yField : String
    , yType : String
    , color : String

    -- "advanced" (the folded section): chart frame + mark options
    , title : String
    , width : String
    , height : String
    , tooltip : Bool
    , point : Bool
    , opacity : String
    , interpolate : String
    , innerRadius : String
    }


default : Form
default =
    { mark = "bar"
    , csv = "category,amount\nApples,28\nPears,55\nPlums,43\nCherries,91\nFigs,81"
    , xField = "category"
    , xType = "nominal"
    , yField = "amount"
    , yType = "quantitative"
    , color = "category"
    , title = "My chart"
    , width = "420"
    , height = "300"
    , tooltip = True
    , point = False
    , opacity = ""
    , interpolate = ""
    , innerRadius = ""
    }


markChoices : List String
markChoices =
    [ "bar", "line", "area", "point", "circle", "arc" ]


typeChoices : List String
typeChoices =
    [ "quantitative", "nominal", "ordinal", "temporal" ]


interpolateChoices : List String
interpolateChoices =
    [ "", "linear", "monotone", "basis", "cardinal", "step" ]



-- CSV PARSING ---------------------------------------------------------------------------------


rows : String -> List (List String)
rows csv =
    csv
        |> String.split "\n"
        |> List.map String.trim
        |> List.filter (\l -> l /= "")
        |> List.map (\l -> List.map String.trim (String.split "," l))


{-| The column headers (the first CSV row). -}
headers : String -> List String
headers csv =
    case rows csv of
        h :: _ ->
            h

        [] ->
            []


{-| The columns, as `(name, values)` pairs. -}
columns : String -> List ( String, List String )
columns csv =
    case rows csv of
        h :: body ->
            List.indexedMap (\i name -> ( name, List.map (cell i) body )) h

        [] ->
            []


cell : Int -> List String -> String
cell i row =
    row |> List.drop i |> List.head |> Maybe.withDefault ""


isNumeric : List String -> Bool
isNumeric values =
    values /= [] && List.all (\v -> String.toFloat v /= Nothing) values



-- CODE GENERATION -----------------------------------------------------------------------------


{-| Generate a complete Elm program for the chosen chart. -}
generate : Form -> String
generate form =
    String.join "\n"
        [ "module Main exposing (main)"
        , ""
        , "import VegaLite exposing (..)"
        , ""
        , ""
        , "main : Spec"
        , "main ="
        , "    toVegaLite"
        , properties form
        , ""
        ]


{-| The `toVegaLite [ … ]` property list (each property prefixed `[ ` / `, ` and closed with `]`). -}
properties : Form -> String
properties form =
    let
        blocks =
            (if String.trim form.title == "" then
                []

             else
                [ "title " ++ quote (String.trim form.title) ]
            )
                ++ [ "width " ++ numOr "400" form.width
                   , "height " ++ numOr "300" form.height
                   , "dataFromColumns\n" ++ dataBlock form.csv
                   , "mark " ++ form.mark ++ " " ++ markProps form
                   , "encoding\n" ++ encodingBlock form
                   ]
    in
    String.join "\n"
        (List.indexedMap
            (\i b ->
                (if i == 0 then
                    "        [ "

                 else
                    "        , "
                )
                    ++ b
            )
            blocks
            ++ [ "        ]" ]
        )


numOr : String -> String -> String
numOr fallback s =
    if String.trim s == "" then
        fallback

    else
        String.trim s


{-| The mark's property list, e.g. `[ maTooltip True, maPoint True ]` (or `[]`). -}
markProps : Form -> String
markProps form =
    let
        ps =
            (if form.tooltip then
                [ "maTooltip True" ]

             else
                []
            )
                ++ (if form.point then
                        [ "maPoint True" ]

                    else
                        []
                   )
                ++ optNum "maOpacity" form.opacity
                ++ (if String.trim form.interpolate == "" then
                        []

                    else
                        [ "maInterpolate " ++ quote (String.trim form.interpolate) ]
                   )
                ++ optNum "maInnerRadius" form.innerRadius
    in
    if List.isEmpty ps then
        "[]"

    else
        "[ " ++ String.join ", " ps ++ " ]"


optNum : String -> String -> List String
optNum fn s =
    if String.trim s == "" then
        []

    else
        [ fn ++ " " ++ String.trim s ]


dataBlock : String -> String
dataBlock csv =
    let
        col ( name, values ) =
            if isNumeric values then
                "( \"" ++ name ++ "\", numbers [ " ++ String.join ", " values ++ " ] )"

            else
                "( \"" ++ name ++ "\", strings [ " ++ String.join ", " (List.map quote values) ++ " ] )"

        items =
            columns csv |> List.map col
    in
    case items of
        [] ->
            "            []"

        first :: rest ->
            String.join "\n"
                (("            [ " ++ first) :: List.map (\c -> "            , " ++ c) rest ++ [ "            ]" ])


encodingBlock : Form -> String
encodingBlock form =
    let
        channel fn fld ty =
            "            , " ++ fn ++ " \"" ++ fld ++ "\" [ " ++ ty ++ " ]"

        xLine =
            "            [ pX \"" ++ form.xField ++ "\" [ " ++ form.xType ++ " ]"

        yLine =
            channel "pY" form.yField form.yType

        colorLines =
            if form.color == "" then
                []

            else
                [ channel "pColor" form.color "nominal" ]
    in
    String.join "\n" (xLine :: yLine :: colorLines ++ [ "            ]" ])


quote : String -> String
quote s =
    "\"" ++ s ++ "\""



-- PARSING (source -> Form), so the Wizard panel reflects the current program -----------------


{-| Best-effort read of a generated program back into the form, so switching the editor's Code ⇄
Wizard panes keeps the form in sync with the source. Anything not recognised falls back to a default.
-}
parse : String -> Form
parse source =
    let
        lines =
            List.map (stripListPrefix << String.trim) (String.lines source)

        markLine =
            lines |> List.filter (String.startsWith "mark ") |> List.head |> Maybe.withDefault ""

        ( colorField, _ ) =
            parseChannel "pColor" lines |> Maybe.withDefault ( "", "" )

        ( xField, xType ) =
            parseChannel "pX" lines |> Maybe.withDefault ( default.xField, default.xType )

        ( yField, yType ) =
            parseChannel "pY" lines |> Maybe.withDefault ( default.yField, default.yType )
    in
    { mark = parseMark lines |> Maybe.withDefault default.mark
    , csv = parseCsv (String.lines source) |> Maybe.withDefault default.csv
    , xField = xField
    , xType = xType
    , yField = yField
    , yType = yType
    , color = colorField
    , title = quotedAfter "title" lines |> Maybe.withDefault ""
    , width = wordAfter "width" lines |> Maybe.withDefault default.width
    , height = wordAfter "height" lines |> Maybe.withDefault default.height
    , tooltip = String.contains "maTooltip True" markLine
    , point = String.contains "maPoint True" markLine
    , opacity = numAfter "maOpacity" markLine |> Maybe.withDefault ""
    , interpolate = strAfter "maInterpolate" markLine |> Maybe.withDefault ""
    , innerRadius = numAfter "maInnerRadius" markLine |> Maybe.withDefault ""
    }


{-| Drop a leading list prefix (`"[ "` on the first item, `", "` on the rest) so every property line
parses the same way. -}
stripListPrefix : String -> String
stripListPrefix s =
    if String.startsWith ", " s || String.startsWith "[ " s then
        String.dropLeft 2 s

    else
        s


{-| The mark name from a `mark <name> [ … ]` line (the second word). -}
parseMark : List String -> Maybe String
parseMark lines =
    lines
        |> List.filterMap
            (\s ->
                if String.startsWith "mark " s then
                    nth 1 (String.words s)

                else
                    Nothing
            )
        |> List.head


{-| The (field, type) of a channel line like `pX "amount" [ quantitative ]`. -}
parseChannel : String -> List String -> Maybe ( String, String )
parseChannel prefix lines =
    lines
        |> List.filterMap
            (\s ->
                if String.startsWith (prefix ++ " \"") s then
                    Maybe.map2 Tuple.pair (nth 1 (String.split "\"" s)) (bracketWord s)

                else
                    Nothing
            )
        |> List.head


{-| The first word inside the `[ … ]` of a line (the field type). -}
bracketWord : String -> Maybe String
bracketWord s =
    s
        |> String.split "["
        |> nth 1
        |> Maybe.andThen (String.split "]" >> List.head)
        |> Maybe.andThen (String.trim >> String.words >> List.head)


{-| The quoted string of a `<token> "…"` line (e.g. `title "Sales"`). -}
quotedAfter : String -> List String -> Maybe String
quotedAfter token lines =
    lines
        |> List.filterMap
            (\s ->
                if String.startsWith (token ++ " \"") s then
                    nth 1 (String.split "\"" s)

                else
                    Nothing
            )
        |> List.head


{-| The bare word of a `<token> <word>` line (e.g. `width 420`). -}
wordAfter : String -> List String -> Maybe String
wordAfter token lines =
    lines
        |> List.filterMap
            (\s ->
                if String.startsWith (token ++ " ") s then
                    nth 1 (String.words s)

                else
                    Nothing
            )
        |> List.head


{-| The numeric value following `<token> ` somewhere in a line (e.g. `maOpacity 0.6` → "0.6"). -}
numAfter : String -> String -> Maybe String
numAfter token line =
    if String.contains (token ++ " ") line then
        String.split (token ++ " ") line
            |> nth 1
            |> Maybe.map (takeUntil [ ' ', ',', ']' ])
            |> Maybe.andThen nonEmpty

    else
        Nothing


{-| The quoted value following `<token> ` (e.g. `maInterpolate "monotone"` → "monotone"). -}
strAfter : String -> String -> Maybe String
strAfter token line =
    if String.contains (token ++ " ") line then
        String.split (token ++ " ") line |> nth 1 |> Maybe.andThen (\s -> nth 1 (String.split "\"" s))

    else
        Nothing


takeUntil : List Char -> String -> String
takeUntil delims s =
    String.fromList (takeWhile (\c -> not (List.member c delims)) (String.toList s))


nonEmpty : String -> Maybe String
nonEmpty s =
    if s == "" then
        Nothing

    else
        Just s


{-| Rebuild the CSV from a `dataFromColumns [ ( "c", strings/numbers [ … ] ) … ]` block. -}
parseCsv : List String -> Maybe String
parseCsv lines =
    let
        afterData =
            dropThrough (String.contains "dataFromColumns") lines

        block =
            takeWhile (\l -> String.trim l /= "]") afterData

        cols =
            List.filterMap parseColumn block
    in
    if List.isEmpty cols then
        Nothing

    else
        Just (columnsToCsv cols)


{-| One `( "name", strings|numbers [ v, v ] )` column line → (name, values). -}
parseColumn : String -> Maybe ( String, List String )
parseColumn line =
    let
        valuesAfter kind =
            if String.contains (kind ++ " [") line then
                String.split (kind ++ " [") line
                    |> nth 1
                    |> Maybe.andThen (String.split "]" >> List.head)
                    |> Maybe.map
                        (String.split ","
                            >> List.map (String.trim >> unquote)
                            >> List.filter (\v -> v /= "")
                        )

            else
                Nothing
    in
    Maybe.map2 Tuple.pair
        (nth 1 (String.split "\"" line))
        (case valuesAfter "strings" of
            Just vs ->
                Just vs

            Nothing ->
                valuesAfter "numbers"
        )


columnsToCsv : List ( String, List String ) -> String
columnsToCsv cols =
    let
        names =
            List.map Tuple.first cols

        valueLists =
            List.map Tuple.second cols

        rowCount =
            valueLists |> List.map List.length |> List.maximum |> Maybe.withDefault 0

        row i =
            String.join "," (List.map (\vs -> nth i vs |> Maybe.withDefault "") valueLists)
    in
    String.join "\n" (String.join "," names :: List.map row (List.range 0 (rowCount - 1)))


unquote : String -> String
unquote s =
    if String.startsWith "\"" s && String.endsWith "\"" s && String.length s >= 2 then
        String.dropLeft 1 (String.dropRight 1 s)

    else
        s


nth : Int -> List a -> Maybe a
nth i xs =
    List.head (List.drop i xs)


dropThrough : (a -> Bool) -> List a -> List a
dropThrough p xs =
    case xs of
        [] ->
            []

        x :: rest ->
            if p x then
                rest

            else
                dropThrough p rest


takeWhile : (a -> Bool) -> List a -> List a
takeWhile p xs =
    case xs of
        [] ->
            []

        x :: rest ->
            if p x then
                x :: takeWhile p rest

            else
                []
