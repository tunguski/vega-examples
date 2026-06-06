port module AreaChart exposing (main)

{-| A filled area chart over a single inline series. -}

import Platform
import Vega exposing (..)


areaChart : Spec
areaChart =
    let
        table =
            dataFromColumns "table" []
                << dataColumn "u" (List.map toFloat (List.range 1 20) |> vNums)
                << dataColumn "v" (vNums [ 28, 55, 43, 91, 81, 53, 19, 87, 52, 48, 24, 49, 87, 66, 17, 27, 68, 16, 49, 15 ])

        ds =
            dataSource [ table [] ]

        sc =
            scales
                << scale "xScale"
                    [ scType scLinear
                    , scRange raWidth
                    , scZero false
                    , scDomain (doData [ daDataset "table", daField (field "u") ])
                    ]
                << scale "yScale"
                    [ scType scLinear
                    , scRange raHeight
                    , scNice niTrue
                    , scZero true
                    , scDomain (doData [ daDataset "table", daField (field "v") ])
                    ]

        ax =
            axes
                << axis "xScale" siBottom [ axTickCount (num 10), axTitle (str "u") ]
                << axis "yScale" siLeft [ axTitle (str "v") ]

        mk =
            marks
                << mark area
                    [ mFrom [ srData (str "table") ]
                    , mEncode
                        [ enEnter
                            [ maX [ vScale "xScale", vField (field "u") ]
                            , maY [ vScale "yScale", vField (field "v") ]
                            , maY2 [ vScale "yScale", vNum 0 ]
                            , maFill [ vStr "steelblue" ]
                            , maInterpolate [ markInterpolationValue miMonotone ]
                            ]
                        , enHover [ maFillOpacity [ vNum 0.5 ] ]
                        , enUpdate [ maFillOpacity [ vNum 1 ] ]
                        ]
                    ]
    in
    toVega [ width 500, height 200, padding 5, ds, sc [], ax [], mk [] ]


mySpecs : Spec
mySpecs =
    combineSpecs [ ( "view", areaChart ) ]


main : Program () Spec msg
main =
    Platform.worker
        { init = always ( mySpecs, elmToJS mySpecs )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


port elmToJS : Spec -> Cmd msg
