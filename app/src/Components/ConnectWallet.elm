module Components.ConnectWallet exposing (view)

import Animator
import Components.DropdownMenu exposing (HiddenMenus)
import Components.Toltips exposing (ShownTooltips)
import Config
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Utils exposing (bulkEther, edges, readableL7l, responsive)



-- VIEW


view :
    { dummyAction : msg
    , title : String
    , iLink : List (Attribute msg) -> String -> Element msg -> Element msg
    , unsupportedNetwork : Bool
    , layout : Device
    , activeProduct : a
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
    }
    -> Element msg
view { dummyAction, unsupportedNetwork, layout, onWalletConnect, onWalletDisconnect, onEthClaim, onTooltipToggle, walletAddress, myGreenBets, myBlueBets, ethBalanceForClaim, l7lBalanceForClaim, disableClaimEth, shownTooltips } =
    case walletAddress of
        Nothing ->
            if unsupportedNetwork then
                column
                    [ spacingXY 0 5, centerX ]
                    [ Input.button
                        [ padding 15
                        , Background.color <| Config.grayColor
                        , Font.color <| Config.whiteColor
                        , Config.mainFont
                        , centerX
                        ]
                        { onPress = Nothing
                        , label = text "Connect wallet"
                        }
                    , paragraph
                        [ Font.italic, Font.size 15, width <| px 300, alignLeft, Font.center ]
                        [ text "To connect, please select Rinkeby or Mainnet Ethereum networks in your wallet" ]
                    ]
            else
                Input.button
                    [ padding 15
                    , Background.color <| Config.highlightColor
                    , Font.color <| Config.whiteColor
                    , Config.mainFont
                    ]
                    { onPress = Just onWalletConnect
                    , label = text "Connect wallet"
                    }

        Just wallet ->
            column
                [ spacing 5
                , Border.width 2
                , Border.color Config.blackColor
                , Font.size <| responsive layout 13 15
                , padding 5
                , alignTop
                ]
                [ row
                    [ width fill
                    , paddingEach { top = responsive layout 5 10, right = responsive layout 5 10, bottom = 5, left = responsive layout 5 10 }
                    ]
                    [ column [ width fill, Font.color Config.grayColor ]
                        [ text wallet
                        ]
                    , el [ alignRight, pointer, Events.onClick onWalletDisconnect ] <| text "X"
                    ]
                , row
                    [ paddingEach { top = 0, right = responsive layout 5 10, bottom = 5, left = responsive layout 5 10 }
                    , width fill
                    ]
                    [ column [ width (fill |> maximum 200 |> minimum ( responsive layout 100 150 ) ) ]
                        [ row [ width fill ]
                            [ column [ Font.color <| Config.grayColor ] [ text "ETH: " ]
                            , column [ paddingXY 3 0 ] [ text <| bulkEther ethBalanceForClaim ]
                            , ethClaimLink layout onEthClaim ethBalanceForClaim disableClaimEth
                            ]
                        ]
                    , column [ width (fill |> maximum 200 |> minimum ( responsive layout 100 150 ) ) ]
                        [ row [ width fill ]
                            [ column [ Font.color <| Config.grayColor ] [ text "L7L: " ]
                            , column [ paddingXY 3 0 ] [ text <| readableL7l l7lBalanceForClaim ]
                            , column
                                [ pointer
                                , paddingXY 3 3
                                , Font.color <| Config.grayColor
                                , Events.onMouseEnter <|
                                    if layout.class == Phone || layout.class == Tablet then
                                        dummyAction

                                    else
                                        onTooltipToggle "claimNotice" True
                                , Events.onMouseLeave <|
                                    if layout.class == Phone || layout.class == Tablet then
                                        dummyAction

                                    else
                                        onTooltipToggle "claimNotice" False
                                , Events.onClick <|
                                    if shownTooltips.claimNotice then
                                        onTooltipToggle "claimNotice" False

                                    else
                                        onTooltipToggle "claimNotice" True
                                ]
                                [ text "claim ⓘ"
                                ]
                            ]
                        ]
                    ]
                , row
                    [ hidden <| not shownTooltips.claimNotice
                    , Font.size 12
                    , alignRight
                    , paddingEach { edges | bottom = 5 }
                    , Font.color <| Config.grayColor
                    , centerX
                    ]
                    [ text "L7L will be claimable after the IDO event" ]
                , row
                    [ paddingEach { top = 0, bottom = responsive layout 5 10, left = responsive layout 5 10, right = responsive layout 5 10 }
                    , width fill
                    ]
                    [ column [ width fill ]
                        [ paragraph []
                            [ el [ Font.color <| Config.blueColor ] <| text "Blue: "
                            , text <| String.append (bulkEther myBlueBets) " ETH"
                            ]
                        ]
                    , column [ width fill ]
                        [ paragraph []
                            [ el [ Font.color <| Config.greenColor ] <| text "Green: "
                            , text <| String.append (bulkEther myGreenBets) " ETH"
                            ]
                        ]
                    ]
                ]


ethClaimLink : Device -> msg -> Float -> Bool -> Element msg
ethClaimLink layout onEthClaim ethBalanceForClaim disableClaimEth =
    if ethBalanceForClaim > 0 then
        if disableClaimEth then
            column
                [ paddingEach { edges | right = 35, left = 5 }
                , Font.color Config.grayColor
                ]
                [ text "claim ⌛"
                ]

        else
            column
                [ pointer
                , paddingEach { edges | right = 35, left = 5 }
                , Font.color Config.highlightColor
                , Events.onClick onEthClaim
                ]
                [ text "claim"
                ]

    else
        column
            [ Font.color Config.grayColor
            , paddingEach { edges | right = 35, left = 5 }
            ]
            [ text "claim"
            ]


hidden : Bool -> Element.Attribute msg
hidden isHidden =
    if isHidden then
        htmlAttribute <| Html.Attributes.style "display" "none"

    else
        htmlAttribute <| Html.Attributes.style "" ""
