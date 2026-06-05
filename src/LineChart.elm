port module LineChart exposing (main)

{-| A multi-series line chart. Two series are drawn by faceting the inline
table on the `c` (category) field and stroking one line mark per group.
-}

import Platform
import Vega exposing (..)


lineChart : Spec
lineChart =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "x" (vNums [ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9 ])
                << dataColumn "y" (vNums [ 28, 20, 43, 35, 81, 10, 19, 15, 52, 48, 24, 28, 87, 66, 17, 27, 68, 16, 49, 25 ])
                << dataColumn "c" (vStrs [ "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b" ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xScale"
                    [ scType scPoint
                    , scRange raWidth
                    , scDomain (doData [ daDataset "table", daField (field "x") ])
                    ]
                << scale "yScale"
                    [ scType scLinear
                    , scRange raHeight
                    , scNice niTrue
                    , scZero true
                    , scDomain (doData [ daDataset "table", daField (field "y") ])
                    ]
                << scale "cScale"
                    [ scType scOrdinal
                    , scRange raCategory
                    , scDomain (doData [ daDataset "table", daField (field "c") ])
                    ]

        ax =
            axes
                << axis "xScale" siBottom [ axTitle (str "x") ]
                << axis "yScale" siLeft [ axTitle (str "y") ]

        mkLine =
            marks
                << mark line
                    [ mFrom [ srData (str "series") ]
                    , mEncode
                        [ enEnter
                            [ maX [ vScale "xScale", vField (field "x") ]
                            , maY [ vScale "yScale", vField (field "y") ]
                            , maStroke [ vScale "cScale", vField (field "c") ]
                            , maStrokeWidth [ vNum 2 ]
                            ]
                        ]
                    ]

        mk =
            marks
                << mark group
                    [ mFrom [ srFacet (str "table") "series" [ faGroupBy [ field "c" ] ] ]
                    , mGroup [ mkLine [] ]
                    ]
    in
    toVega [ width 500, height 200, padding 5, ds, sc [], ax [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", lineChart ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
