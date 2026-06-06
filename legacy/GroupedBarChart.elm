port module GroupedBarChart exposing (main)

{-| A grouped (clustered) bar chart. The table is faceted by `category`; inside
each facet a nested band scale (`pos`) lays the sub-bars out by `position`, and a
group-level `height` signal sizes each cluster to the outer band width. -}

import Platform
import Vega exposing (..)


groupedBar : Spec
groupedBar =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "category" (vStrs [ "A", "A", "A", "B", "B", "B", "C", "C", "C", "D", "D", "D" ])
                << dataColumn "position" (vNums [ 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2 ])
                << dataColumn "value" (vNums [ 28, 55, 43, 91, 81, 53, 19, 87, 52, 48, 24, 49 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "yScale"
                    [ scType scBand
                    , scDomain (doData [ daDataset "table", daField (field "category") ])
                    , scRange raHeight
                    , scPadding (num 0.2)
                    ]
                << scale "xScale"
                    [ scType scLinear
                    , scDomain (doData [ daDataset "table", daField (field "value") ])
                    , scRange raWidth
                    , scRound true
                    , scZero true
                    , scNice niTrue
                    ]
                << scale "cScale"
                    [ scType scOrdinal
                    , scDomain (doData [ daDataset "table", daField (field "position") ])
                    , scRange (raScheme (str "category10") [])
                    ]

        ax =
            axes
                << axis "yScale" siLeft [ axTickCount (num 0), axTitle (str "Category") ]
                << axis "xScale" siBottom [ axTitle (str "Value") ]

        le =
            legends
                << legend [ leFill "cScale", leTitle (str "Series") ]

        groupSignals =
            signals
                << signal "height" [ siUpdate "bandwidth('yScale')" ]

        posScale =
            scales
                << scale "pos"
                    [ scType scBand
                    , scRange raHeight
                    , scDomain (doData [ daDataset "facet", daField (field "position") ])
                    ]

        barMarks =
            marks
                << mark rect
                    [ mFrom [ srData (str "facet") ]
                    , mEncode
                        [ enEnter
                            [ maY [ vScale "pos", vField (field "position") ]
                            , maHeight [ vScale "pos", vBand (num 1) ]
                            , maX [ vScale "xScale", vField (field "value") ]
                            , maX2 [ vScale "xScale", vNum 0 ]
                            , maFill [ vScale "cScale", vField (field "position") ]
                            ]
                        ]
                    ]

        mk =
            marks
                << mark group
                    [ mFrom [ srFacet (str "table") "facet" [ faGroupBy [ field "category" ] ] ]
                    , mEncode
                        [ enEnter [ maY [ vScale "yScale", vField (field "category") ] ] ]
                    , mGroup [ groupSignals [], posScale [], barMarks [] ]
                    ]
    in
    toVega [ width 400, height 240, padding 5, ds, sc [], ax [], le [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", groupedBar ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
