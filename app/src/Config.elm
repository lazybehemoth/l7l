module Config exposing
    ( blackColor
    , blueColor
    , grayColor
    , greenColor
    , h1FontSize
    , highlightColor
    , mainColor
    , mainFont
    , redColor
    , whiteColor
    )

import Element exposing (..)
import Element.Font as Font



-- VIEW


mainColor : Color
mainColor =
    rgb255 0 240 255


whiteColor : Color
whiteColor =
    rgb255 255 255 255


blackColor : Color
blackColor =
    rgb255 0 0 0


grayColor : Color
grayColor =
    rgb255 0xC0 0xC0 0xC0


blueColor : Color
blueColor =
    mainColor


greenColor : Color
greenColor =
    rgb255 0 240 140


redColor : Color
redColor =
    rgb255 196 90 90


highlightColor : Color
highlightColor =
    rgb255 255 15 115


h1FontSize : Attribute msg
h1FontSize =
    let
        scaled =
            Element.modular 40 1.25
    in
    Font.size (scaled 1 |> round)


mainFont : Attribute msg
mainFont =
    Font.family
        [ Font.typeface "Helvetica Neue"
        , Font.sansSerif
        ]
