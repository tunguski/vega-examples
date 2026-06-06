port module HorizontalBarChart exposing (main)

{-| A horizontal bar chart: categories run down the y axis, bar length encodes
the value along x. Labels are drawn at the end of each bar. -}

import Platform
import Vega exposing (..)


horizontalBar : Spec
horizontalBar =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "category" (vStrs [ "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot" ])
                << dataColumn "amount" (vNums [ 28, 55, 43, 91, 81, 53 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "yScale"
                    [ scType scBand
                    , scDomain (doData [ daDataset "table", daField (field "category") ])
                    , scRange raHeight
                    , scPadding (num 0.1)
                    ]
                << scale "xScale"
                    [ scType scLinear
                    , scDomain (doData [ daDataset "table", daField (field "amount") ])
                    , scRange raWidth
                    , scNice niTrue
                    ]

        ax =
            axes
                << axis "yScale" siLeft [ axTitle (str "Category") ]
                << axis "xScale" siBottom [ axTitle (str "Amount") ]

        mk =
            marks
                << mark rect
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maY [ vScale "yScale", vField (field "category") ]
                            , maHeight [ vScale "yScale", vBand (num 1) ]
                            , maX [ vScale "xScale", vNum 0 ]
                            , maX2 [ vScale "xScale", vField (field "amount") ]
                            ]
                        , enUpdate [ maFill [ vStr "seagreen" ] ]
                        , enHover [ maFill [ vStr "orange" ] ]
                        ]
                    ]
                << mark text
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maY [ vScale "yScale", vField (field "category"), vBand (num 0.5) ]
                            , maX [ vScale "xScale", vField (field "amount"), vOffset (vNum 4) ]
                            , maBaseline [ vMiddle ]
                            , maAlign [ hLeft ]
                            , maFill [ vStr "#333" ]
                            , maText [ vField (field "amount") ]
                            ]
                        ]
                    ]
    in
    toVega [ width 400, height 200, padding 5, ds, sc [], ax [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", horizontalBar ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
