port module Heatmap exposing (main)

{-| A heatmap: a grid of `rect` cells positioned by two band scales (day × hour)
and coloured by value through a sequential colour scale. -}

import Platform
import Vega exposing (..)


heatmap : Spec
heatmap =
    let
        -- A 5 (day) × 4 (slot) grid, flattened into parallel columns.
        days =
            [ "Mon", "Tue", "Wed", "Thu", "Fri" ]

        slots =
            [ "Morning", "Noon", "Afternoon", "Evening" ]

        grid =
            List.concatMap (\d -> List.map (\s -> ( d, s )) slots) days

        values =
            [ 12, 28, 45, 18, 9, 33, 52, 24, 15, 40, 61, 30, 8, 22, 38, 14, 20, 48, 70, 41 ]

        table =
            dataFromColumns "table" []
                << dataColumn "day" (vStrs (List.map Tuple.first grid))
                << dataColumn "slot" (vStrs (List.map Tuple.second grid))
                << dataColumn "value" (vNums values)

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xScale"
                    [ scType scBand
                    , scDomain (doStrs (strs days))
                    , scRange raWidth
                    ]
                << scale "yScale"
                    [ scType scBand
                    , scDomain (doStrs (strs slots))
                    , scRange raHeight
                    ]
                << scale "cScale"
                    [ scType scSequential
                    , scRange (raScheme (str "viridis") [])
                    , scDomain (doData [ daDataset "table", daField (field "value") ])
                    , scZero true
                    ]

        ax =
            axes
                << axis "xScale" siBottom [ axDomain false, axTitle (str "Day") ]
                << axis "yScale" siLeft [ axDomain false, axTitle (str "Slot") ]

        le =
            legends
                << legend [ leFill "cScale", leType ltGradient, leTitle (str "Value") ]

        mk =
            marks
                << mark rect
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maX [ vScale "xScale", vField (field "day") ]
                            , maWidth [ vScale "xScale", vBand (num 1) ]
                            , maY [ vScale "yScale", vField (field "slot") ]
                            , maHeight [ vScale "yScale", vBand (num 1) ]
                            , maTooltip [ vField (field "value") ]
                            ]
                        , enUpdate [ maFill [ vScale "cScale", vField (field "value") ] ]
                        ]
                    ]
    in
    toVega [ width 300, height 240, padding 5, ds, sc [], ax [], le [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", heatmap ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
