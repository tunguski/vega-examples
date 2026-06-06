port module StackedBarChart exposing (main)

{-| A stacked bar chart: two series (`c` = 0 or 1) stacked per `x` position via
the Vega `stack` transform (producing `y0`/`y1` bounds for each segment). -}

import Platform
import Vega exposing (..)


stackedBar : Spec
stackedBar =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "x" (vNums [ 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9 ])
                << dataColumn "y" (vNums [ 28, 55, 43, 91, 81, 53, 19, 87, 52, 48, 24, 49, 87, 66, 17, 27, 68, 16, 49, 15 ])
                << dataColumn "c" (vStrs [ "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b", "a", "b" ])

        ds =
            dataSource
                [ table []
                    |> transform
                        [ trStack
                            [ stGroupBy [ field "x" ]
                            , stSort [ ( field "c", ascend ) ]
                            , stField (field "y")
                            ]
                        ]
                ]

        sc =
            scales
                << scale "xScale"
                    [ scType scBand
                    , scRange raWidth
                    , scDomain (doData [ daDataset "table", daField (field "x") ])
                    ]
                << scale "yScale"
                    [ scType scLinear
                    , scRange raHeight
                    , scNice niTrue
                    , scZero true
                    , scDomain (doData [ daDataset "table", daField (field "y1") ])
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

        mk =
            marks
                << mark rect
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maX [ vScale "xScale", vField (field "x") ]
                            , maWidth [ vScale "xScale", vBand (num 1), vOffset (vNum -1) ]
                            , maY [ vScale "yScale", vField (field "y0") ]
                            , maY2 [ vScale "yScale", vField (field "y1") ]
                            , maFill [ vScale "cScale", vField (field "c") ]
                            ]
                        , enUpdate [ maFillOpacity [ vNum 1 ] ]
                        , enHover [ maFillOpacity [ vNum 0.5 ] ]
                        ]
                    ]
    in
    toVega [ width 400, height 200, padding 5, ds, sc [], ax [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", stackedBar ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
