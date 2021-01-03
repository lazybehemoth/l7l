module Components.Layout.Header exposing (ProductType(..), view)

import Animator
import Animator.Css
import Components.ConnectWallet
import Components.DropdownMenu exposing (HiddenMenus)
import Components.Logo as Logo
import Components.Toltips exposing (ShownTooltips)
import Config
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Element.Font as Font exposing (center)
import Element.Region as Region
import Html
import Html.Attributes
import Process
import String exposing (toInt)
import Task
import Utils exposing (edges, responsive)


type ProductType
    = Random
    | Margin
    | None


view :
    { dummyAction : msg
    , title : String
    , iLink : List (Attribute msg) -> String -> Element msg -> Element msg
    , layout : Device
    , activeProduct : ProductType
    , onWalletConnect : msg
    , onWalletDisconnect : msg
    , onEthClaim : msg
    , onToggleMobileMenu : msg
    , onTooltipToggle : String -> Bool -> msg
    , onMenuToggle : String -> Bool -> msg
    , walletAddress : Maybe String
    , myGreenBets : Float
    , myBlueBets : Float
    , ethBalanceForClaim : Float
    , l7lBalanceForClaim : Float
    , disableClaimEth : Bool
    , mobileMenuOpening : Bool
    , mobileMenuHidden : Animator.Timeline Bool
    , shownTooltips : ShownTooltips
    , hiddenMenus : HiddenMenus
    , closedEarnL7lModal : Bool
    , closeEarnL7L : msg
    }
    -> Element msg
view options =
    let
        rp =
            Utils.responsive options.layout 10 20

        menuHeight =
            Animator.Css.height <|
                \state ->
                    if state then
                        Animator.once Animator.slowly <| Animator.wave 250 0

                    else
                        Animator.once Animator.slowly <| Animator.wave 0 250

        headerLead =
            if options.activeProduct /= None then
                productSelector options.layout options.activeProduct options.shownTooltips options.onTooltipToggle options.iLink

            else
                el
                    [ width fill
                    , Font.bold
                    , Font.center
                    , Font.size <| responsive options.layout 24 28
                    ]
                <|
                    text options.title
    in
    if (options.layout.class == Phone || options.layout.class == Tablet) || options.layout.orientation == Portrait then
        column [ width fill ]
            [ row [ width fill, paddingEach { edges | top = rp, right = rp, left = rp }, spacing 0 ]
                [ column [ width <| px 60, centerY ]
                    [ if options.activeProduct /= None then
                        Logo.view options.layout options.iLink

                      else
                        options.iLink [ Font.size 30 ] "/" (text "❮")
                    ]
                , headerLead
                , column [ width <| px 60 ]
                    [ el
                        [ Font.size 30
                        , paddingXY 5 0
                        , Font.color Config.blackColor
                        , alignRight
                        , alignTop
                        , pointer
                        , onClick options.onToggleMobileMenu
                        ]
                      <|
                        text <|
                            if Animator.current options.mobileMenuHidden then
                                "☰"

                            else
                                "✕"
                    ]
                ]
            , row
                [ width fill
                , paddingEach { edges | top = 10 }
                , Background.color Config.whiteColor
                , Element.below <|
                    el [ height fill, width fill ] <|
                        html <|
                            mobileMenu options.mobileMenuHidden options.mobileMenuOpening options.hiddenMenus options.onMenuToggle options.onToggleMobileMenu options.iLink
                ]
                [ none
                ]
            , if options.activeProduct /= None then
                earnL7LLead options.iLink options.closeEarnL7L options.closedEarnL7lModal

              else
                none
            , row [ width fill, centerX, paddingXY 0 20 ]
                [ column [ centerX ] [ Components.ConnectWallet.view options ]
                ]
            , row [ width fill, centerX, paddingEach { edges | bottom = 10 }, hidden <| options.activeProduct /= Random ]
                [ leverageSelector options.layout 2 options.shownTooltips options.onTooltipToggle options.dummyAction
                ]
            ]

    else
        column [ width fill ]
            [ row [ width fill, paddingEach { edges | top = rp, right = rp, left = rp }, spacing 20 ]
                [ column [ width <| px 200, alignTop ] [ Logo.view options.layout options.iLink ]
                , links options.hiddenMenus options.onMenuToggle options.iLink
                , column [ width <| px 200, alignTop ] [ el [ alignRight ] <| Components.ConnectWallet.view options ]
                ]
            , row [ width fill, centerX, paddingEach { edges | bottom = 40, top = if options.walletAddress == Nothing then 40 else 0 } ]
                [ productSelector options.layout options.activeProduct options.shownTooltips options.onTooltipToggle options.iLink
                ]
            , row [ width fill, centerX, paddingEach { edges | bottom = 10 }, hidden <| options.activeProduct /= Random ]
                [ leverageSelector options.layout 2 options.shownTooltips options.onTooltipToggle options.dummyAction
                ]
            ]


mobileMenu :
    Animator.Timeline Bool
    -> Bool
    -> HiddenMenus
    -> (String -> Bool -> msg)
    -> msg
    -> (List (Attribute msg) -> String -> Element msg -> Element msg)
    -> Html.Html msg
mobileMenu mobileMenuHidden mobileMenuOpening hiddenMenus onMenuToggle onToggleMobileMenu iLink =
    let
        menuHeight =
            Animator.Css.height <|
                \state ->
                    if state then
                        Animator.at 0

                    else
                        Animator.at (toFloat <| mobileMenuHeight hiddenMenus)

        renderedMenu =
            layoutWith
                { options = [ noStaticStyleSheet ] }
                [ width fill
                , height <| px (mobileMenuHeight hiddenMenus)
                ]
            <|
                column
                    [ width fill
                    , height fill
                    , alignLeft
                    , alignTop
                    , Region.navigation
                    , Background.color Config.whiteColor
                    , spacing 20
                    , paddingXY 0 35
                    , Font.semiBold
                    , Border.color Config.grayColor
                    , Border.widthEach { edges | top = 1, bottom = 1 }
                    ]
                    [ Components.DropdownMenu.mobileView "products"
                        (el [ paddingXY 23 0 ] <| text "Products")
                        hiddenMenus
                        onMenuToggle
                      <|
                        productLinks False
                    , Components.DropdownMenu.mobileView "about"
                        (el [ paddingXY 23 0 ] <| text "About LE7EL")
                        hiddenMenus
                        onMenuToggle
                      <|
                        aboutLinks False
                    , Components.DropdownMenu.mobileView "builders"
                        (el [ paddingXY 23 0 ] <| text "For builders")
                        hiddenMenus
                        onMenuToggle
                      <|
                        buildersLinks False
                    , iLink
                        [ pointer
                        , paddingXY 23 0
                        , onClick onToggleMobileMenu
                        ]
                        "/#/earnl7l"
                        (text "Earn L7L")
                    ]
    in
    if not (Animator.current mobileMenuHidden) && not mobileMenuOpening then
        Html.div
            [ Html.Attributes.style "width" "100%"
            ]
            [ renderedMenu ]

    else
        Animator.Css.div mobileMenuHidden
            [ menuHeight
            ]
            [ Html.Attributes.style "width" "100%"
            , Html.Attributes.style "height" "0"
            , Html.Attributes.style "overflow" "hidden"
            ]
            [ renderedMenu ]


mobileMenuHeight : HiddenMenus -> Int
mobileMenuHeight hiddenMenus =
    let
        baseMenuHeight =
            173

        productsMenuHeight =
            if not hiddenMenus.products then
                baseMenuHeight + 60

            else
                baseMenuHeight

        aboutMenuHeight =
            if not hiddenMenus.about then
                productsMenuHeight + 200

            else
                productsMenuHeight
    in
    if not hiddenMenus.builders then
        aboutMenuHeight + 35

    else
        aboutMenuHeight


links :
    HiddenMenus
    -> (String -> Bool -> msg)
    -> (List (Attribute msg) -> String -> Element msg -> Element msg)
    -> Element msg
links hiddenMenus onMenuToggle iLink =
    column [ width fill, alignTop, Region.navigation, paddingEach { edges | top = 10 } ]
        [ row [ width fill, spacingXY 40 70 ]
            [ column [ centerX ]
                [ Components.DropdownMenu.view "products"
                    "delayedProducts"
                    "inProducts"
                    (text "Products")
                    hiddenMenus
                    onMenuToggle
                  <|
                    productLinks True
                ]
            , column [ centerX ]
                [ Components.DropdownMenu.view "about"
                    "delayedAbout"
                    "inAbout"
                    (text "About")
                    hiddenMenus
                    onMenuToggle
                  <|
                    aboutLinks True
                ]
            , column [ centerX ]
                [ Components.DropdownMenu.view "builders"
                    "delayedBuilders"
                    "inBuilders"
                    (text "Builders")
                    hiddenMenus
                    onMenuToggle
                  <|
                    buildersLinks True
                ]
            , column [ centerX ]
                [ iLink
                    [ padding 10
                    , pointer
                    , Border.width 1
                    , Background.color Config.whiteColor
                    , Font.color Config.blackColor
                    ]
                    "/#/earnl7l"
                    (text "Earn L7L")
                ]
            ]
        ]


productLinks : Bool -> List (Element msg)
productLinks newTab =
    [ newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/products/l7l-random"
        , label = text "L7L Random"
        }
    , newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/products/l7l-margin"
        , label = text "L7L Margin"
        }
    ]


aboutLinks : Bool -> List (Element msg)
aboutLinks newTab =
    [ newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/introduction/le7el-introduction"
        , label = text "LE7EL Introduction"
        }
    , newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/about/le7el-dao-and-governance"
        , label = text "LE7EL DAO & Governance"
        }
    , newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/about/l7l-token-economics"
        , label = text "L7L token economics"
        }
    , newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/about/l7l-token-distribution"
        , label = text "L7L token distribution"
        }
    , newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/about/where-to-get-l7l"
        , label = text "Where to buy L7L"
        }
    ]


buildersLinks : Bool -> List (Element msg)
buildersLinks newTab =
    [ newTabLinkIf newTab
        []
        { url = "https://docs.le7el.com/for-builders/docs"
        , label = text "Docs"
        }
    ]


productSelector :
    Device
    -> ProductType
    -> ShownTooltips
    -> (String -> Bool -> msg)
    -> (List (Attribute msg) -> String -> Element msg -> Element msg)
    -> Element msg
productSelector layout activeProduct shownTooltips onTooltipToggle iLink =
    let
        btnStyles =
            [ centerX
            , width <| px <| responsive layout 90 120
            , Font.center
            , Font.size <| responsive layout 16 22
            , padding <| responsive layout 10 15
            , Border.width 2
            , Border.color Config.blackColor
            ]

        activeStyles_ =
            [ Font.color Config.blackColor
            , Background.color Config.whiteColor
            ]

        inactiveStyles_ =
            [ Font.color Config.whiteColor
            , Background.color Config.blackColor
            ]
    in
    case activeProduct of
        Margin ->
            row [ width fill ]
                [ column (btnStyles ++ inactiveStyles_)
                    [ iLink
                        [ centerX
                        , pointer
                        ]
                        "/"
                        (text "Random")
                    ]
                , column (btnStyles ++ activeStyles_) [ el [ centerX ] <| text "Margin" ]
                ]

        Random ->
            row [ width fill ]
                [ column (btnStyles ++ activeStyles_) [ el [ centerX ] <| text "Random" ]
                , column (btnStyles ++ inactiveStyles_)
                    [ iLink
                        [ centerX
                        , pointer
                        ]
                        "/#/margin"
                        (text "Margin")
                    ]
                ]

        None ->
            row [ width fill, notVisible True ] []


leverageSelector : Device -> Int -> ShownTooltips -> (String -> Bool -> msg) -> msg -> Element msg
leverageSelector layout activeLeverage shownTooltips onTooltipToggle noAction =
    let
        isNoticeHidden leverage =
            case leverage of
                5 ->
                    shownTooltips.random5x

                10 ->
                    shownTooltips.random10x

                100 ->
                    shownTooltips.random100x

                1000 ->
                    shownTooltips.random1000x

                _ ->
                    True

        activeStyles leverage =
            if leverage == activeLeverage then
                [ centerX
                , Font.bold
                , paddingEach { edges | bottom = 3, top = 10, right = 15, left = 15 }
                ]

            else
                [ centerX
                , Font.bold
                , pointer
                , paddingEach { edges | top = 10, right = 15, left = 15 }
                , onMouseEnter <|
                    if layout.class == Phone then
                        noAction

                    else
                        onTooltipToggle (String.concat [ "random", String.fromInt leverage, "x" ]) False
                , onMouseLeave <|
                    if layout.class == Phone then
                        noAction

                    else
                        onTooltipToggle (String.concat [ "random", String.fromInt leverage, "x" ]) True
                , onClick <|
                    onTooltipToggle
                        (String.concat [ "random", String.fromInt leverage, "x" ])
                    <|
                        not (isNoticeHidden leverage)
                , Element.below <|
                    el
                        [ moveDown 10
                        , Font.size 16
                        , Font.center
                        , Font.light

                        --, moveLeft 32
                        , notVisible <| isNoticeHidden leverage
                        ]
                    <|
                        text "coming soon!"
                ]

        renderOption leverage =
            column (activeStyles leverage)
                [ el
                    (if leverage == activeLeverage then
                        [ Border.widthEach { edges | bottom = 1 }, moveDown 2 ]

                     else
                        []
                    )
                  <|
                    text <|
                        String.append (String.fromInt leverage) "x"
                ]
    in
    row [ width fill, centerX ] <|
        List.map renderOption [ 2, 5, 10, 100, 1000 ]


earnL7LLead : (List (Attribute msg) -> String -> Element msg -> Element msg) -> msg -> Bool -> Element msg
earnL7LLead iLink closeEarnL7L closedEarnL7lModal =
    row 
        [ width fill
        , centerX
        , Font.center
        , Font.color Config.whiteColor
        , Background.color Config.grayColor
        , Font.size 14
        , padding 5
        ]
        [ el [ centerX ] (text "Earn the L7L token by ")
        , iLink [ pointer, centerX ]
            "/#/earnl7l" <|
            el [ Font.underline ] <| text "inviting your friends"
        ]
        


hidden : Bool -> Element.Attribute msg
hidden isHidden =
    if isHidden then
        htmlAttribute <| Html.Attributes.style "display" "none"

    else
        htmlAttribute <| Html.Attributes.style "" ""


notVisible : Bool -> Element.Attribute msg
notVisible isHidden =
    if isHidden then
        htmlAttribute <| Html.Attributes.style "visibility" "hidden"

    else
        htmlAttribute <| Html.Attributes.style "" ""


newTabLinkIf : Bool -> List (Element.Attribute msg) -> { url : String, label : Element msg } -> Element msg
newTabLinkIf newTab attrs params =
    if newTab then
        link ([ htmlAttribute <| Html.Attributes.target "_blank" ] ++ attrs) params

    else
        link attrs params
