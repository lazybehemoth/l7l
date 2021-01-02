module Components.Logo exposing (view)

import Element exposing (..)



-- VIEW


view : Device -> (List (Attribute msg) -> String -> Element msg -> Element msg) -> Element msg
view layout iLink =
    case layout.class of
        Phone ->
            el [ width <| px 50, height <| px 50 ] <|
                iLink [] "/" <|
                    image [ width fill, paddingEach { top = 5, bottom = 5, left = 5, right = 5 } ]
                        { src = "./icon.svg"
                        , description = "LE7EL"
                        }

        _ ->
            el [ width <| (fill |> maximum 200 |> minimum 150), height fill ] <|
                iLink [] "/" <|
                    image [ width fill, height fill, paddingXY 25 10 ]
                        { src = "./logo.svg"
                        , description = "LE7EL"
                        }
