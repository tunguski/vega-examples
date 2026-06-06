module VegaLite exposing
    ( Spec, toVegaLite
    , title, description, width, height
    , dataFromColumns, Column, numbers, strings
    , Mark, mark, bar, line, area, point, circle, square, tick, rect, arc
    , MarkProperty, maColor, maOpacity, maTooltip, maPoint, maInterpolate, maInnerRadius
    , encoding, FieldProp
    , pX, pY, pColor, pSize, pTheta, pTooltip
    , field, nominal, quantitative, ordinal, temporal
    , aggregate, binned, scale, axisTitle, legendNone
    )

{-| A compact, editor-interpretable subset of the
[Vega-Lite](https://vega.github.io/vega-lite/) grammar, in the spirit of
[gicentre/elm-vegalite](https://package.elm-lang.org/packages/gicentre/elm-vegalite/latest/).

It is built entirely on the `Json.Encode` operations the elm-lang in-browser editor interpreter
supports, so a chart written against it can be evaluated live in the browser and the resulting
spec handed to vega-embed.

A chart is a `Spec` (a JSON value). Build one with `toVegaLite`, passing a list of properties:

    chart : Spec
    chart =
        toVegaLite
            [ title "Monthly sales"
            , width 400
            , height 300
            , dataFromColumns
                [ ( "month", strings [ "Jan", "Feb", "Mar", "Apr", "May" ] )
                , ( "sales", numbers [ 28, 55, 43, 91, 81 ] )
                ]
            , mark bar []
            , encoding
                [ pX "month" [ nominal ]
                , pY "sales" [ quantitative ]
                , pColor "month" [ nominal ]
                ]
            ]

-}

import Json.Encode as Encode


{-| A Vega-Lite specification — a JSON value. -}
type alias Spec =
    Encode.Value


vegaLiteSchema : String
vegaLiteSchema =
    "https://vega.github.io/schema/vega-lite/v5.json"


{-| Assemble a list of top-level properties into a complete spec (adds the `$schema`). -}
toVegaLite : List ( String, Spec ) -> Spec
toVegaLite props =
    Encode.object (( "$schema", Encode.string vegaLiteSchema ) :: props)



-- TOP-LEVEL PROPERTIES ------------------------------------------------------------------------


title : String -> ( String, Spec )
title t =
    ( "title", Encode.string t )


description : String -> ( String, Spec )
description d =
    ( "description", Encode.string d )


width : Float -> ( String, Spec )
width w =
    ( "width", Encode.float w )


height : Float -> ( String, Spec )
height h =
    ( "height", Encode.float h )



-- DATA ----------------------------------------------------------------------------------------


{-| A column of inline data: either numbers or strings. -}
type Column
    = NumCol (List Float)
    | StrCol (List String)


numbers : List Float -> Column
numbers =
    NumCol


strings : List String -> Column
strings =
    StrCol


{-| Inline data given as named columns; transposed into row objects under `data.values`. -}
dataFromColumns : List ( String, Column ) -> ( String, Spec )
dataFromColumns cols =
    let
        rowCount =
            cols |> List.map (Tuple.second >> columnLength) |> List.maximum |> Maybe.withDefault 0

        row i =
            Encode.object (List.map (\( name, col ) -> ( name, cellAt i col )) cols)

        rows =
            List.map row (List.range 0 (rowCount - 1))
    in
    ( "data", Encode.object [ ( "values", Encode.list identity rows ) ] )


columnLength : Column -> Int
columnLength col =
    case col of
        NumCol xs ->
            List.length xs

        StrCol xs ->
            List.length xs


cellAt : Int -> Column -> Spec
cellAt i col =
    case col of
        NumCol xs ->
            Encode.float (xs |> List.drop i |> List.head |> Maybe.withDefault 0)

        StrCol xs ->
            Encode.string (xs |> List.drop i |> List.head |> Maybe.withDefault "")



-- MARKS ---------------------------------------------------------------------------------------


type Mark
    = Mark String


bar : Mark
bar =
    Mark "bar"


line : Mark
line =
    Mark "line"


area : Mark
area =
    Mark "area"


point : Mark
point =
    Mark "point"


circle : Mark
circle =
    Mark "circle"


square : Mark
square =
    Mark "square"


tick : Mark
tick =
    Mark "tick"


rect : Mark
rect =
    Mark "rect"


arc : Mark
arc =
    Mark "arc"


type MarkProperty
    = MarkProperty ( String, Spec )


maColor : String -> MarkProperty
maColor c =
    MarkProperty ( "color", Encode.string c )


maOpacity : Float -> MarkProperty
maOpacity o =
    MarkProperty ( "opacity", Encode.float o )


maTooltip : Bool -> MarkProperty
maTooltip b =
    MarkProperty ( "tooltip", Encode.bool b )


maPoint : Bool -> MarkProperty
maPoint b =
    MarkProperty ( "point", Encode.bool b )


maInterpolate : String -> MarkProperty
maInterpolate s =
    MarkProperty ( "interpolate", Encode.string s )


maInnerRadius : Float -> MarkProperty
maInnerRadius r =
    MarkProperty ( "innerRadius", Encode.float r )


{-| The chart's mark, with optional properties. With no properties it is the bare mark name. -}
mark : Mark -> List MarkProperty -> ( String, Spec )
mark (Mark name) props =
    case props of
        [] ->
            ( "mark", Encode.string name )

        _ ->
            ( "mark"
            , Encode.object (( "type", Encode.string name ) :: List.map (\(MarkProperty p) -> p) props)
            )



-- ENCODING ------------------------------------------------------------------------------------


{-| The encoding: a list of channel definitions (`pX`, `pY`, `pColor`, …). -}
encoding : List ( String, Spec ) -> ( String, Spec )
encoding channels =
    ( "encoding", Encode.object channels )


type FieldProp
    = FieldProp ( String, Spec )


channel : String -> String -> List FieldProp -> ( String, Spec )
channel chan name props =
    let
        base =
            if name == "" then
                []

            else
                [ ( "field", Encode.string name ) ]
    in
    ( chan, Encode.object (base ++ List.map (\(FieldProp p) -> p) props) )


pX : String -> List FieldProp -> ( String, Spec )
pX =
    channel "x"


pY : String -> List FieldProp -> ( String, Spec )
pY =
    channel "y"


pColor : String -> List FieldProp -> ( String, Spec )
pColor =
    channel "color"


pSize : String -> List FieldProp -> ( String, Spec )
pSize =
    channel "size"


pTheta : String -> List FieldProp -> ( String, Spec )
pTheta =
    channel "theta"


pTooltip : String -> List FieldProp -> ( String, Spec )
pTooltip =
    channel "tooltip"


{-| Set (or override) the channel's field by name. Usually you pass the name to `pX`/`pY`/… directly. -}
field : String -> FieldProp
field name =
    FieldProp ( "field", Encode.string name )


nominal : FieldProp
nominal =
    FieldProp ( "type", Encode.string "nominal" )


quantitative : FieldProp
quantitative =
    FieldProp ( "type", Encode.string "quantitative" )


ordinal : FieldProp
ordinal =
    FieldProp ( "type", Encode.string "ordinal" )


temporal : FieldProp
temporal =
    FieldProp ( "type", Encode.string "temporal" )


{-| An aggregate operation, e.g. `aggregate "sum"`, `aggregate "mean"`, `aggregate "count"`. -}
aggregate : String -> FieldProp
aggregate op =
    FieldProp ( "aggregate", Encode.string op )


binned : FieldProp
binned =
    FieldProp ( "bin", Encode.bool True )


{-| Set the channel's scale scheme, e.g. `scale "category10"`. -}
scale : String -> FieldProp
scale scheme =
    FieldProp ( "scale", Encode.object [ ( "scheme", Encode.string scheme ) ] )


axisTitle : String -> FieldProp
axisTitle t =
    FieldProp ( "title", Encode.string t )


legendNone : FieldProp
legendNone =
    FieldProp ( "legend", Encode.null )
