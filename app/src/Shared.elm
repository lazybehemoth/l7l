module Shared exposing
    ( Flags
    , Model
    , Msg(..), RoundResult, Bet
    , init
    , link
    , maskWallet
    , subscriptions
    , update
    , view
    )

import Animator
import Animator.Css
import Browser.Events
import Browser.Navigation exposing (Key)
import Components.DropdownMenu exposing (HiddenMenus)
import Components.Layout.Footer as Footer
import Components.Layout.Header as Header
import Components.Toltips exposing (ShownTooltips)
import Element exposing (..)
import Element.Region as Region
import Html.Events exposing (preventDefaultOn)
import Json.Decode as D
import Ports
import Process
import Spa.Document exposing (Document)
import Spa.Generated.Route
import Task
import Time
import Url exposing (Url)
import Utils



-- INIT


type alias Flags =
    { url : String
    , https : Bool
    , domain : String
    , http_port : Int
    , x2eth_address : String
    , x2eth_history_address : String
    , inner_width : Int
    , inner_height : Int
    }


type ClaimState
    = NoClaim
    | InWalletClaim
    | PendingClaim
    | CompletedClaim
    | FailedClaim

type alias Bet =
    { address : String
    , amount : String
    }


type alias RoundResult =
    { round : Int
    , transactionHash : String
    , result : String
    , totalBooty : String
    , totalWinners : String
    , myBetSide : Maybe String
    , myBetAmount : Maybe String
    }


type alias Model =
    { url : Url
    , key : Maybe Key
    , innerWidth : Int
    , innerHeight : Int
    , x2ethAddress : String
    , x2ethHistoryAddress : String
    , walletAddress : Maybe String
    , myGreenBets : Float
    , myBlueBets : Float
    , ethWalletBalance : Float
    , ethBalanceForClaim : Float
    , l7lBalanceForClaim : Float
    , claimEthState : ClaimState
    , mobileMenuOpening : Bool
    , mobileMenuHidden : Animator.Timeline Bool
    , shownTooltips : ShownTooltips
    , hiddenMenus : HiddenMenus
    , roundEndsIn : Int
    , greenBets : List Bet
    , blueBets : List Bet
    , totalGreenBooty : Float
    , totalBlueBooty : Float
    , resultsHistoryPage : Int
    , resultsHistory : List RoundResult
    , currentRound : Int
    , l7lRewardCof : Float
    , pendingL7lReward : Float
    }


defaultTooltips : ShownTooltips
defaultTooltips =
    { random5x = True
    , random10x = True
    , random100x = True
    , random1000x = True
    , claimNotice = False
    }


defaultMenus : HiddenMenus
defaultMenus =
    { products = True
    , inProducts = False
    , about = True
    , inAbout = False
    , builders = True
    , inBuilders = False
    }


init : Flags -> Url -> ( Model, Cmd Msg )
init flags url =
    ( Model
        url
        Nothing
        flags.inner_width
        flags.inner_height
        flags.x2eth_address
        flags.x2eth_history_address
        Nothing
        0.0
        0.0
        0.0
        0.0
        0.0
        NoClaim
        False
        (Animator.init True)
        defaultTooltips
        defaultMenus
        -100000
        []
        []
        0.0
        0.0
        1
        []
        1
        100.0
        0.0
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoAction
    | ChangeUrl String
    | Tick Time.Posix
    | ResizeWindow Int Int
    | ConnectWallet
    | ChangeWallet
    | WalletConnected String
    | EthWalletBalance String
    | EthBalanceForClaim String
    | L7lBalanceForClaim String
    | ClaimEth
    | ClaimEthState Int
    | ToggleMobileMenu
    | OpenedMobileMenu
    | ShowTooltip String Bool
    | ToggleMenu String Bool


animator : Animator.Animator Model
animator =
    Animator.animator
        -- *NOTE*  We're using `the Animator.Css.watching` instead of `Animator.watching`.
        -- Instead of asking for a constant stream of animation frames, it'll only ask for one
        -- and we'll render the entire css animation in that frame.
        |> Animator.Css.watching .mobileMenuHidden
            (\newState model ->
                { model | mobileMenuHidden = newState }
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoAction ->
            ( model, Cmd.none )

        ChangeUrl newUrl ->
            ( model, Ports.pushUrl newUrl )

        Tick newTime ->
            ( Animator.update newTime animator model
            , Cmd.none
            )

        ResizeWindow w h ->
            ( { model | innerWidth = w, innerHeight = h }, Cmd.none )

        ConnectWallet ->
            ( model, Ports.connectWallet "" )

        ChangeWallet ->
            ( model, Ports.changeWallet "" )

        WalletConnected address ->
            ( { model
                | walletAddress =
                    if address == "" then
                        Nothing

                    else
                        Just address
              }
            , Ports.resultsHistoryPage 1
            )

        EthWalletBalance rawBalance ->
            case String.toFloat rawBalance of
                Just balance ->
                    ( { model | ethWalletBalance = balance }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        EthBalanceForClaim rawBalance ->
            case String.toFloat rawBalance of
                Just balance ->
                    ( { model | ethBalanceForClaim = balance }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        L7lBalanceForClaim rawBalance ->
            case String.toFloat rawBalance of
                Just balance ->
                    ( { model | l7lBalanceForClaim = balance }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ClaimEth ->
            ( { model | claimEthState = InWalletClaim }, Ports.claimEth "" )

        ClaimEthState 0 ->
            ( { model | claimEthState = PendingClaim }, Cmd.none )

        ClaimEthState state ->
            if state > 0 then
                ( { model | claimEthState = CompletedClaim }, Cmd.none )

            else
                ( { model | claimEthState = FailedClaim }, Cmd.none )

        ShowTooltip option state ->
            let
                hideWithDelay =
                    if state || model.innerWidth > 1200 then
                        Cmd.none
                    else
                        Process.sleep 1000 |> Task.perform (always <| ShowTooltip option True)

                hideClaimWithDelay =
                    if state && model.innerWidth < 1201 then
                        Process.sleep 2500 |> Task.perform (always <| ShowTooltip option False)
                    else
                        Cmd.none

                shownTooltips =
                    model.shownTooltips
            in
            case option of
                "claimNotice" ->
                    ( { model | shownTooltips = { shownTooltips | claimNotice = state } }, hideClaimWithDelay )

                "random5x" ->
                    ( { model | shownTooltips = { shownTooltips | random5x = state } }, hideWithDelay )

                "random10x" ->
                    ( { model | shownTooltips = { shownTooltips | random10x = state } }, hideWithDelay )

                "random100x" ->
                    ( { model | shownTooltips = { shownTooltips | random100x = state } }, hideWithDelay )

                "random1000x" ->
                    ( { model | shownTooltips = { shownTooltips | random1000x = state } }, hideWithDelay )

                _ ->
                    ( model, Cmd.none )

        OpenedMobileMenu ->
            ( { model | mobileMenuOpening = False }, Cmd.none )

        ToggleMobileMenu ->
            if Animator.current model.mobileMenuHidden then
                ( { model
                    | mobileMenuOpening = True
                    , mobileMenuHidden =
                        model.mobileMenuHidden
                            |> Animator.go Animator.quickly False
                  }
                , Process.sleep 500 |> Task.perform (always OpenedMobileMenu)
                )

            else
                ( { model
                    | mobileMenuHidden =
                        model.mobileMenuHidden
                            |> Animator.go Animator.quickly True
                  }
                , Cmd.none
                )

        ToggleMenu option state ->
            let
                hiddenMenus =
                    model.hiddenMenus
            in
            case option of
                "products" ->
                    ( { model | hiddenMenus = { hiddenMenus | products = state } }, Cmd.none )

                "delayedProducts" ->
                    ( model, Process.sleep 100 |> Task.perform (always (ToggleMenu "products" state)) )

                "inProducts" ->
                    ( { model | hiddenMenus = { hiddenMenus | inProducts = state } }, Cmd.none )

                "about" ->
                    ( { model | hiddenMenus = { hiddenMenus | about = state } }, Cmd.none )

                "delayedAbout" ->
                    ( model, Process.sleep 100 |> Task.perform (always (ToggleMenu "about" state)) )

                "inAbout" ->
                    ( { model | hiddenMenus = { hiddenMenus | inAbout = state } }, Cmd.none )

                "builders" ->
                    ( { model | hiddenMenus = { hiddenMenus | builders = state } }, Cmd.none )

                "delayedBuilders" ->
                    ( model, Process.sleep 100 |> Task.perform (always (ToggleMenu "builders" state)) )

                "inBuilders" ->
                    ( { model | hiddenMenus = { hiddenMenus | inBuilders = state } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Browser.Events.onResize (\w h -> ResizeWindow w h)
        , Ports.walletConnected WalletConnected
        , Ports.updateEthWalletBalance EthWalletBalance
        , Ports.updateEthBalanceForClaim EthBalanceForClaim
        , Ports.updateL7lBalanceForClaim L7lBalanceForClaim
        , Ports.claimEthState ClaimEthState
        , Animator.toSubscription Tick model animator
        ]



-- VIEW


view :
    { page : Document msg, toMsg : Msg -> msg }
    -> Model
    -> Document msg
view { page, toMsg } model =
    { title = page.title
    , body =
        [ Header.view
            { dummyAction = toMsg NoAction
            , title = page.title
            , iLink = link toMsg
            , unsupportedNetwork = model.x2ethAddress == ""
            , activeProduct = productByTitle page.title
            , layout = classifyDevice { width = model.innerWidth, height = model.innerHeight }
            , onWalletConnect = toMsg ConnectWallet
            , onWalletDisconnect = toMsg ChangeWallet
            , onEthClaim = toMsg ClaimEth
            , onToggleMobileMenu = toMsg ToggleMobileMenu
            , onTooltipToggle = \option state -> toMsg <| ShowTooltip option state
            , onMenuToggle = \option state -> toMsg <| ToggleMenu option state
            , walletAddress = maskWallet model.walletAddress
            , myGreenBets = model.myGreenBets
            , myBlueBets = model.myBlueBets
            , ethBalanceForClaim = model.ethBalanceForClaim
            , l7lBalanceForClaim = model.l7lBalanceForClaim
            , disableClaimEth = model.claimEthState == InWalletClaim || model.claimEthState == PendingClaim
            , mobileMenuOpening = model.mobileMenuOpening
            , mobileMenuHidden = model.mobileMenuHidden
            , shownTooltips = model.shownTooltips
            , hiddenMenus = model.hiddenMenus
            }
        , column [ centerX, width fill, Region.mainContent ] page.body
        , Footer.view <| classifyDevice { width = model.innerWidth, height = model.innerHeight }
        ]
    }


link : (Msg -> msg) -> List (Attribute msg) -> String -> Element msg -> Element msg
link toMsg attrs url label =
    Element.link (htmlAttribute (preventDefaultOn "click" (D.succeed ( toMsg <| ChangeUrl url, True ))) :: attrs)
        { url = url
        , label = label
        }


maskWallet : Maybe String -> Maybe String
maskWallet walletAddress =
    Maybe.map (\wallet -> Utils.shortWallet 19 wallet) walletAddress


productByTitle : String -> Header.ProductType
productByTitle title =
    case title of
        "L7L Margin" ->
            Header.Margin

        "L7L Random" ->
            Header.Random

        _ ->
            Header.None
