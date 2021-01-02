module Components.DropdownMenu exposing (..)

import Config
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font
import Html.Attributes


type alias HiddenMenus =
    { products : Bool
    , inProducts : Bool
    , about : Bool
    , inAbout : Bool
    , builders : Bool
    , inBuilders : Bool
    }



-- VIEW


view : String -> String -> String -> Element msg -> HiddenMenus -> (String -> Bool -> msg) -> List (Element msg) -> Element msg
view menu delayedMenu inMenu labelEl hiddenMenus onMenuToggle links =
    row
        [ pointer
        , onMouseEnter <| onMenuToggle menu False
        , onMouseLeave <| onMenuToggle delayedMenu True
        , Element.below <|
            column
                [ paddingXY 20 20
                , spacing 20
                , width (fill |> minimum 280)
                , onMouseEnter <| onMenuToggle inMenu True
                , onMouseLeave <| onMenuToggle inMenu False
                , Background.color Config.whiteColor
                , Border.width 1
                , Border.color Config.grayColor
                , moveLeft 20
                , moveDown 5
                , hidden <| isHiddenMenu menu hiddenMenus
                ]
                links
        ]
        [ labelEl, el [ rotate <| degrees 90.0, paddingXY 5 0 ] <| text "❯" ]


mobileView : String -> Element msg -> HiddenMenus -> (String -> Bool -> msg) -> List (Element msg) -> Element msg
mobileView menu labelEl hiddenMenus onMenuToggle links =
    column [ width fill ]
        [ row
            [ pointer
            , width fill
            , onClick <| onMenuToggle menu <| not <| isHiddenMenu menu hiddenMenus
            ]
            [ labelEl
            , el [ alignRight, moveLeft 20, rotate <| degrees 90.0 ] <| text "❯"
            ]
        , row
            [ width fill
            , Background.color Config.whiteColor
            , Border.color Config.grayColor
            , hidden <| isHiddenMenu menu hiddenMenus
            ]
            [ column
                [ paddingEach { left = 23, right = 23, top = 20, bottom = 0 }
                , Font.size 16
                , spacing 20
                , width fill
                ]
                links
            ]
        ]


isHiddenMenu : String -> HiddenMenus -> Bool
isHiddenMenu menu hiddenMenus =
    case menu of
        "products" ->
            hiddenMenus.products && not hiddenMenus.inProducts

        "about" ->
            hiddenMenus.about && not hiddenMenus.inAbout

        "builders" ->
            hiddenMenus.builders && not hiddenMenus.inBuilders

        _ ->
            True


hidden : Bool -> Element.Attribute msg
hidden isHidden =
    if isHidden then
        htmlAttribute <| Html.Attributes.style "display" "none"

    else
        htmlAttribute <| Html.Attributes.style "" ""
