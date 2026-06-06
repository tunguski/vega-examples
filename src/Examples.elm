module Examples exposing (Example, all, starter)

{-| The built-in example charts. Each is a complete program written against the `VegaLite`
module: a top-level `main` whose value is a `Spec`. The editor interprets it live and renders
the resulting Vega-Lite spec.
-}


type alias Example =
    { name : String
    , code : String
    }


{-| The program shown on first load. -}
starter : String
starter =
    bar


all : List Example
all =
    [ Example "Bar chart" bar
    , Example "Grouped bar" groupedBar
    , Example "Line chart" lineChart
    , Example "Area chart" areaChart
    , Example "Scatter plot" scatter
    , Example "Bubble plot" bubble
    , Example "Pie chart" pie
    , Example "Donut chart" donut
    , Example "Histogram" histogram
    ]


bar : String
bar =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Monthly sales"
        , width 420
        , height 300
        , dataFromColumns
            [ ( "month", strings [ "Jan", "Feb", "Mar", "Apr", "May", "Jun" ] )
            , ( "sales", numbers [ 28, 55, 43, 91, 81, 53 ] )
            ]
        , mark bar [ maTooltip True ]
        , encoding
            [ pX "month" [ nominal ]
            , pY "sales" [ quantitative ]
            , pColor "month" [ nominal, legendNone ]
            ]
        ]
"""


groupedBar : String
groupedBar =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Sales by quarter and region"
        , width 420
        , height 300
        , dataFromColumns
            [ ( "quarter", strings [ "Q1", "Q1", "Q2", "Q2", "Q3", "Q3", "Q4", "Q4" ] )
            , ( "region", strings [ "North", "South", "North", "South", "North", "South", "North", "South" ] )
            , ( "sales", numbers [ 28, 19, 55, 43, 81, 60, 53, 49 ] )
            ]
        , mark bar [ maTooltip True ]
        , encoding
            [ pX "region" [ nominal ]
            , pY "sales" [ quantitative ]
            , pColor "region" [ nominal ]
            ]
        ]
"""


lineChart : String
lineChart =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Temperature over the day"
        , width 460
        , height 280
        , dataFromColumns
            [ ( "hour", numbers [ 0, 3, 6, 9, 12, 15, 18, 21 ] )
            , ( "temp", numbers [ 8, 7, 10, 16, 21, 23, 19, 13 ] )
            ]
        , mark line [ maPoint True, maInterpolate "monotone" ]
        , encoding
            [ pX "hour" [ quantitative ]
            , pY "temp" [ quantitative ]
            ]
        ]
"""


areaChart : String
areaChart =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Visitors per week"
        , width 460
        , height 260
        , dataFromColumns
            [ ( "week", numbers [ 1, 2, 3, 4, 5, 6, 7, 8 ] )
            , ( "visitors", numbers [ 120, 180, 150, 240, 300, 280, 360, 410 ] )
            ]
        , mark area [ maOpacity 0.7, maInterpolate "monotone" ]
        , encoding
            [ pX "week" [ quantitative ]
            , pY "visitors" [ quantitative ]
            ]
        ]
"""


scatter : String
scatter =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Horsepower vs. mileage"
        , width 360
        , height 360
        , dataFromColumns
            [ ( "hp", numbers [ 130, 165, 150, 95, 88, 110, 90, 175, 153, 68 ] )
            , ( "mpg", numbers [ 18, 15, 16, 24, 27, 24, 30, 15, 20, 33 ] )
            ]
        , mark circle [ maOpacity 0.6, maTooltip True ]
        , encoding
            [ pX "hp" [ quantitative ]
            , pY "mpg" [ quantitative ]
            ]
        ]
"""


bubble : String
bubble =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Bubble plot"
        , width 380
        , height 360
        , dataFromColumns
            [ ( "x", numbers [ 1, 2, 3, 4, 5, 6, 7, 8 ] )
            , ( "y", numbers [ 12, 28, 17, 35, 22, 41, 30, 48 ] )
            , ( "size", numbers [ 20, 60, 40, 90, 50, 120, 70, 150 ] )
            , ( "group", strings [ "a", "b", "a", "b", "a", "b", "a", "b" ] )
            ]
        , mark circle [ maOpacity 0.65, maTooltip True ]
        , encoding
            [ pX "x" [ quantitative ]
            , pY "y" [ quantitative ]
            , pSize "size" [ quantitative ]
            , pColor "group" [ nominal ]
            ]
        ]
"""


pie : String
pie =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Market share"
        , width 320
        , height 320
        , dataFromColumns
            [ ( "company", strings [ "A", "B", "C", "D", "E" ] )
            , ( "share", numbers [ 35, 25, 20, 12, 8 ] )
            ]
        , mark arc [ maTooltip True ]
        , encoding
            [ pTheta "share" [ quantitative ]
            , pColor "company" [ nominal ]
            ]
        ]
"""


donut : String
donut =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Traffic sources"
        , width 320
        , height 320
        , dataFromColumns
            [ ( "source", strings [ "Email", "Social", "Search", "Direct", "Referral" ] )
            , ( "visits", numbers [ 32, 25, 18, 15, 10 ] )
            ]
        , mark arc [ maInnerRadius 70, maTooltip True ]
        , encoding
            [ pTheta "visits" [ quantitative ]
            , pColor "source" [ nominal ]
            ]
        ]
"""


histogram : String
histogram =
    """module Main exposing (main)

import VegaLite exposing (..)


main : Spec
main =
    toVegaLite
        [ title "Distribution of scores"
        , width 420
        , height 280
        , dataFromColumns
            [ ( "score", numbers [ 55, 62, 68, 71, 73, 74, 77, 78, 79, 81, 82, 84, 85, 88, 90, 92, 95, 67, 72, 86 ] )
            ]
        , mark bar [ maTooltip True ]
        , encoding
            [ pX "score" [ quantitative, binned ]
            , pY "score" [ aggregate "count" ]
            ]
        ]
"""
