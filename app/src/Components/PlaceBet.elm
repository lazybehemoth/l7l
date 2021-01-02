module Components.PlaceBet exposing (view)

import Config
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html.Attributes



-- VIEW


view : { onBet : msg, disabled : Bool } -> Element msg
view { onBet, disabled } =
    Input.button
        [ padding 20
        , Background.color <|
            if disabled then
                Config.grayColor

            else
                Config.blackColor
        , Font.color <| Config.whiteColor
        , Font.size 26
        , Config.mainFont
        , htmlAttribute <| Html.Attributes.disabled True
        ]
        { onPress =
            if disabled then
                Nothing

            else
                Just onBet
        , label = text "Place bet"
        }
