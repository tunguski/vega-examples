port module DonutChart exposing (main)

{-| A donut chart: like the pie, but the arcs have a non-zero inner radius so
the centre is hollow. -}

import Platform
import Vega exposing (..)


donutChart : Spec
donutChart =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "id" (vStrs [ "Email", "Social", "Search", "Direct", "Referral" ])
                << dataColumn "field" (vNums [ 32, 25, 18, 15, 10 ])

        ds =
            dataSource
                [ table []
                    |> transform [ trPie [ piField (field "field") ] ]
                ]

        sc =
            scales
                << scale "cScale"
                    [ scType scOrdinal
                    , scRange (raScheme (str "tableau10") [])
                    , scDomain (doData [ daDataset "table", daField (field "id") ])
                    ]

        le =
            legends
                << legend [ leFill "cScale", leTitle (str "Channel") ]

        mk =
            marks
                << mark arc
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maFill [ vScale "cScale", vField (field "id") ]
                            , maX [ vSignal "width / 2" ]
                            , maY [ vSignal "height / 2" ]
                            , maStartAngle [ vField (field "startAngle") ]
                            , maEndAngle [ vField (field "endAngle") ]
                            , maInnerRadius [ vNum 50 ]
                            , maOuterRadius [ vSignal "width / 2" ]
                            , maCornerRadius [ vNum 3 ]
                            , maStroke [ vStr "white" ]
                            , maStrokeWidth [ vNum 2 ]
                            ]
                        ]
                    ]
    in
    toVega [ width 240, height 240, autosize [ asNone ], ds, sc [], le [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", donutChart ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
