module Wizard exposing (Form, default, headers, generate, markChoices, typeChoices)

{-| The "new chart" wizard: turns a chart type + a small CSV dataset + a field mapping into a
ready-to-edit Elm program written against the `VegaLite` module. Pure helpers (parsing + code
generation); the form UI and messages live in `Main`.
-}


type alias Form =
    { name : String
    , mark : String
    , csv : String
    , xField : String
    , xType : String
    , yField : String
    , yType : String
    , color : String
    }


default : Form
default =
    { name = ""
    , mark = "bar"
    , csv = "category,amount\nApples,28\nPears,55\nPlums,43\nCherries,91\nFigs,81"
    , xField = "category"
    , xType = "nominal"
    , yField = "amount"
    , yType = "quantitative"
    , color = "category"
    }


markChoices : List String
markChoices =
    [ "bar", "line", "area", "point", "circle", "arc" ]


typeChoices : List String
typeChoices =
    [ "quantitative", "nominal", "ordinal", "temporal" ]



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


{-| A valid Elm module name derived from the user's name (capitalised, alphanumerics only). -}
safeModule : String -> String
safeModule name =
    let
        cleaned =
            String.filter (\c -> Char.isAlphaNum c) name
    in
    case String.uncons cleaned of
        Just ( first, rest ) ->
            String.toUpper (String.fromChar first) ++ rest

        Nothing ->
            "Chart"


{-| Generate a complete Elm program for the chosen chart. -}
generate : Form -> String
generate form =
    String.join "\n"
        [ "module " ++ safeModule form.name ++ " exposing (main)"
        , ""
        , "import VegaLite exposing (..)"
        , ""
        , ""
        , "main : Spec"
        , "main ="
        , "    toVegaLite"
        , "        [ title \"My chart\""
        , "        , width 420"
        , "        , height 300"
        , "        , dataFromColumns"
        , dataBlock form.csv
        , "        , mark " ++ form.mark ++ " [ maTooltip True ]"
        , "        , encoding"
        , encodingBlock form
        , "        ]"
        , ""
        ]


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
