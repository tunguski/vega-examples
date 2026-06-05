port module PieChart exposing (main)

{-| A pie chart: the Vega `pie` transform turns each datum's value into a
start/end angle, and one arc mark per slice fills the disc. -}

import Platform
import Vega exposing (..)


pieChart : Spec
pieChart =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "id" (vStrs [ "A", "B", "C", "D", "E", "F" ])
                << dataColumn "field" (vNums [ 4, 6, 10, 3, 7, 8 ])

        ds =
            dataSource
                [ table []
                    |> transform [ trPie [ piField (field "field") ] ]
                ]

        sc =
            scales
                << scale "cScale"
                    [ scType scOrdinal
                    , scRange (raScheme (str "category10") [])
                    , scDomain (doData [ daDataset "table", daField (field "id") ])
                    ]

        le =
            legends
                << legend [ leFill "cScale", leTitle (str "Group") ]

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
                            , maOuterRadius [ vSignal "width / 2" ]
                            , maStroke [ vStr "white" ]
                            , maStrokeWidth [ vNum 1 ]
                            ]
                        ]
                    ]
    in
    toVega [ width 240, height 240, autosize [ asNone ], ds, sc [], le [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", pieChart ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
