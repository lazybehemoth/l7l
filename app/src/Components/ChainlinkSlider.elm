module Components.ChainlinkSlider exposing (view)

import Config
import Element exposing (..)
import Element.Events exposing (onClick)
import Element.Font as Font
import Html.Attributes



-- VIEW


view : { maxSlide : Int, currentSlide : Int, onNextSlide : msg, onPrevSlide : msg } -> Element msg
view { maxSlide, currentSlide, onNextSlide, onPrevSlide } =
    column [ paddingXY 0 20 ]
        [ row [ width fill ] <|
            [ column [ centerX ]
                --, notVisible <| currentSlide == 1 ]
                [ el [ Font.size 60, pointer, Font.color Config.blackColor, padding 50, onClick onPrevSlide ] <| text "❮"
                ]
            , column [ centerX ]
                [ image [ height <| px 200 ]
                    { src = String.concat [ "./link", String.fromInt currentSlide, ".png" ]
                    , description = titleForSlide currentSlide
                    }
                ]
            , column [ centerX ]
                --, notVisible <| currentSlide == 4 ]
                [ el [ Font.size 60, pointer, Font.color Config.blackColor, padding 50, onClick onNextSlide ] <| text "❯"
                ]
            ]
        , row [ centerX, paddingXY 0 10, Font.center ]
            [ paragraph [ Font.size 16, width <| px 350 ] [ text <| titleForSlide currentSlide ]
            ]
        ]


titleForSlide : Int -> String
titleForSlide currentSlide =
    case currentSlide of
        1 ->
            "LE7EL sends request for randomness"

        2 ->
            "Chainlink generates randomness and sends proofs to the VRF contracts"

        3 ->
            "The VRF contract verifies the randomness"

        _ ->
            "LE7EL recieves verified randomness"


notVisible : Bool -> Element.Attribute msg
notVisible isHidden =
    if isHidden then
        htmlAttribute <| Html.Attributes.style "visibility" "hidden"

    else
        htmlAttribute <| Html.Attributes.style "" ""
