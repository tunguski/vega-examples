port module BarChart exposing (main)

{-| A basic vertical bar chart with inline data and a hover highlight.

Built with the elm-vega `Vega` module (full Vega grammar): the Elm code is a
declarative description of the chart that compiles to a Vega JSON spec, which is
sent out the `elmToJS` port and rendered in the browser by vega-embed.
-}

import Platform
import Vega exposing (..)


barChart : Spec
barChart =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "category" (vStrs [ "A", "B", "C", "D", "E", "F", "G", "H" ])
                << dataColumn "amount" (vNums [ 28, 55, 43, 91, 81, 53, 19, 87 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xScale"
                    [ scType scBand
                    , scDomain (doData [ daDataset "table", daField (field "category") ])
                    , scRange raWidth
                    , scPadding (num 0.05)
                    ]
                << scale "yScale"
                    [ scType scLinear
                    , scDomain (doData [ daDataset "table", daField (field "amount") ])
                    , scRange raHeight
                    , scNice niTrue
                    ]

        ax =
            axes
                << axis "xScale" siBottom [ axTitle (str "Category") ]
                << axis "yScale" siLeft [ axTitle (str "Amount") ]

        mk =
            marks
                << mark rect
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maX [ vScale "xScale", vField (field "category") ]
                            , maWidth [ vScale "xScale", vBand (num 1) ]
                            , maY [ vScale "yScale", vField (field "amount") ]
                            , maY2 [ vScale "yScale", vNum 0 ]
                            ]
                        , enUpdate [ maFill [ vStr "steelblue" ] ]
                        , enHover [ maFill [ vStr "orange" ] ]
                        ]
                    ]
    in
    toVega [ width 400, height 200, padding 5, ds, sc [], ax [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", barChart ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
