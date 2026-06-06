port module ScatterPlot exposing (main)

{-| A scatterplot of inline car-like data: horsepower against miles-per-gallon,
with point size encoding acceleration. -}

import Platform
import Vega exposing (..)


scatterPlot : Spec
scatterPlot =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "hp" (vNums [ 130, 165, 150, 140, 198, 220, 215, 95, 88, 110, 90, 105, 175, 153, 68 ])
                << dataColumn "mpg" (vNums [ 18, 15, 16, 17, 15, 14, 14, 24, 27, 24, 30, 26, 15, 20, 33 ])
                << dataColumn "accel" (vNums [ 12, 11.5, 11, 12, 10, 9, 8.5, 15, 17.5, 14, 16, 14.5, 9.5, 13, 19 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xScale"
                    [ scType scLinear
                    , scRound true
                    , scNice niTrue
                    , scZero true
                    , scDomain (doData [ daDataset "table", daField (field "hp") ])
                    , scRange raWidth
                    ]
                << scale "yScale"
                    [ scType scLinear
                    , scRound true
                    , scNice niTrue
                    , scZero true
                    , scDomain (doData [ daDataset "table", daField (field "mpg") ])
                    , scRange raHeight
                    ]
                << scale "sizeScale"
                    [ scType scLinear
                    , scRound true
                    , scZero true
                    , scDomain (doData [ daDataset "table", daField (field "accel") ])
                    , scRange (raNums [ 16, 361 ])
                    ]

        ax =
            axes
                << axis "xScale" siBottom [ axGrid true, axTickCount (num 5), axTitle (str "Horsepower") ]
                << axis "yScale" siLeft [ axGrid true, axTickCount (num 5), axTitle (str "Miles per gallon") ]

        mk =
            marks
                << mark symbol
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enUpdate
                            [ maX [ vScale "xScale", vField (field "hp") ]
                            , maY [ vScale "yScale", vField (field "mpg") ]
                            , maSize [ vScale "sizeScale", vField (field "accel") ]
                            , maShape [ symbolValue symCircle ]
                            , maFill [ vStr "#4682b4" ]
                            , maFillOpacity [ vNum 0.5 ]
                            , maStroke [ vStr "#4682b4" ]
                            , maStrokeWidth [ vNum 1 ]
                            ]
                        ]
                    ]
    in
    toVega [ width 300, height 300, padding 5, ds, sc [], ax [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", scatterPlot ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
