module Pages.Top exposing (Model, Msg, Params, page)

import Components.ChainlinkSlider as ChainlinkSlider
import Components.PlaceBet
import Config
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick, onFocus, onLoseFocus)
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html
import Html.Attributes
import Json.Decode exposing (Decoder, bool, decodeValue, field, int, list, map2, map6, map7, nullable, string)
import Json.Encode
import Ports
import Process
import Shared exposing (Bet, RoundResult)
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Task
import Utils exposing (edges, getBlockchainExplorer, responsive)


type alias Params =
    ()


type BetType
    = Green
    | Blue


type BetStatus
    = NoBet
    | Confirmed
    | InWallet
    | Pending
    | Failed


type alias Model =
    { layout : Device
    , blockchainExplorer : String
    , x2ethAddress : String
    , x2ethHistoryAddress : String
    , walletAddress : Maybe String
    , betType : BetType
    , betTypeLabel : String
    , l7lRewardCof : Float
    , pendingL7lReward : Float
    , currentColor : Element.Color
    , amount : Float
    , rawAmount : String
    , greenBets : List Bet
    , blueBets : List Bet
    , totalGreenBooty : Float
    , totalBlueBooty : Float
    , ethWalletBalance : Float
    , betStatus : BetStatus
    , currentRound : Int
    , roundEndsIn : Int
    , resultsHistoryPage : Int
    , resultsHistory : List RoundResult
    , outcomes : List Outcome
    , currentChainlinkSlide : Int
    }


type alias Outcome =
    { win : Bool
    , block : Int
    , transactionHash : String
    , round : Int
    , address : String
    , amount : String
    , result : String
    }


type Msg
    = ChoseBetType BetType
    | ConnectWallet
    | CurrentColor Element.Color Element.Color
    | ChangeBetAmount String
    | FinaliseBetAmount
    | PutBetAmount
    | PutBetAmountAllIn
    | CommitBet BetType Float
    | BetCommitment Int
    | DecodeBets BetType Json.Encode.Value
    | GreenBooty String
    | BlueBooty String
    | CurrentRound Int
    | LoadHistoryPage Int
    | DecodeResultsHistory Json.Encode.Value
    | RoundEndsIn Int
    | UpdateCountdown
    | DecodeOutcome Json.Encode.Value
    | OutcomeClosed Outcome
    | LinkRewardCof Float
    | PendingL7lReward String
    | ChainlinkSlide Int


estimatedGasForBet : Float
estimatedGasForBet =
    20000000000000000.0


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , save = save
        , load = load
        }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared url =
    ( { layout = classifyDevice { height = shared.innerHeight, width = shared.innerWidth }
      , blockchainExplorer = getBlockchainExplorer url.rawUrl.host
      , x2ethAddress = shared.x2ethAddress
      , x2ethHistoryAddress = shared.x2ethHistoryAddress
      , walletAddress = shared.walletAddress
      , betType = Green
      , betTypeLabel = ""
      , l7lRewardCof = shared.l7lRewardCof
      , pendingL7lReward = shared.pendingL7lReward
      , currentColor = Config.blueColor
      , rawAmount = String.fromFloat <| Utils.weiToEther shared.ethWalletBalance
      , amount = Utils.weiToEther shared.ethWalletBalance
      , greenBets = shared.greenBets
      , blueBets = shared.blueBets
      , totalGreenBooty = shared.totalGreenBooty
      , totalBlueBooty = shared.totalBlueBooty
      , ethWalletBalance = shared.ethWalletBalance
      , betStatus = NoBet
      , currentRound = shared.currentRound
      , roundEndsIn = shared.roundEndsIn
      , resultsHistoryPage = shared.resultsHistoryPage
      , resultsHistory = shared.resultsHistory
      , outcomes = []
      , currentChainlinkSlide = 1
      }
    , Cmd.batch
        [ Process.sleep 100 |> Task.perform (always (CurrentColor Config.blueColor Config.greenColor))
        ]
    )


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { layout = classifyDevice { height = shared.innerHeight, width = shared.innerWidth }
      , blockchainExplorer = getBlockchainExplorer shared.url.host
      , x2ethAddress = shared.x2ethAddress
      , x2ethHistoryAddress = shared.x2ethHistoryAddress
      , walletAddress = shared.walletAddress
      , betType = model.betType
      , betTypeLabel = ""
      , l7lRewardCof = shared.l7lRewardCof
      , pendingL7lReward = shared.pendingL7lReward
      , currentColor = model.currentColor
      , rawAmount = String.fromFloat <| Utils.weiToEther shared.ethWalletBalance
      , amount = Utils.weiToEther shared.ethWalletBalance
      , greenBets = shared.greenBets
      , blueBets = shared.blueBets
      , totalGreenBooty = shared.totalGreenBooty
      , totalBlueBooty = shared.totalBlueBooty
      , ethWalletBalance = shared.ethWalletBalance
      , betStatus = model.betStatus
      , currentRound = shared.currentRound
      , roundEndsIn = shared.roundEndsIn
      , resultsHistoryPage = shared.resultsHistoryPage
      , resultsHistory = shared.resultsHistory
      , outcomes = model.outcomes
      , currentChainlinkSlide = model.currentChainlinkSlide
      }
    , Cmd.none
    )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    let
        addMyBet bet total =
            case shared.walletAddress of
                Just wallet ->
                    if String.toLower bet.address == String.toLower wallet then
                        case String.toFloat bet.amount of
                            Just amount ->
                                total + amount

                            Nothing ->
                                total

                    else
                        total

                Nothing ->
                    total
    in
    { shared 
        | myGreenBets = List.foldl addMyBet 0 model.greenBets
        , myBlueBets = List.foldl addMyBet 0 model.blueBets
        , roundEndsIn = model.roundEndsIn
        , greenBets = model.greenBets
        , blueBets = model.blueBets
        , totalGreenBooty = model.totalGreenBooty
        , totalBlueBooty = model.totalBlueBooty
        , resultsHistoryPage = model.resultsHistoryPage
        , resultsHistory = model.resultsHistory
        , currentRound = model.currentRound
        , l7lRewardCof = model.l7lRewardCof
        , pendingL7lReward = model.pendingL7lReward
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.betCommitment BetCommitment
        , Ports.greenBets (DecodeBets Green)
        , Ports.blueBets (DecodeBets Blue)
        , Ports.totalGreenBooty GreenBooty
        , Ports.totalBlueBooty BlueBooty
        , Ports.currentRound CurrentRound
        , Ports.resultsHistory DecodeResultsHistory
        , Ports.roundEndsIn RoundEndsIn
        , Ports.notifyResult DecodeOutcome
        , Ports.updateL7lReward LinkRewardCof
        , Ports.updatePendingL7lReward PendingL7lReward
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkRewardCof cof ->
            ( { model | l7lRewardCof = cof }, Cmd.none )

        PendingL7lReward pendingL7l ->
            case String.toFloat pendingL7l of
                Just amount ->
                    ( { model | pendingL7lReward = amount }, Cmd.none )

                Nothing ->
                    ( { model | pendingL7lReward = 0 }, Cmd.none )

        ChoseBetType Green ->
            if model.roundEndsIn < 3600 && model.totalGreenBooty > 0 then
                ( { model | betTypeLabel = "Closed (too many bets), bet Blue" }, Cmd.none )

            else
                ( { model | betType = Green }, Cmd.none )

        ChoseBetType Blue ->
            if model.roundEndsIn < 3600 && model.totalBlueBooty > 0 then
                ( { model | betTypeLabel = "Closed (too many bets), bet Green" }, Cmd.none )

            else
                ( { model | betType = Blue }, Cmd.none )

        ConnectWallet ->
            ( model, Ports.connectWallet "" )

        CurrentColor color1 color2 ->
            ( { model | currentColor = color1 }, Process.sleep 3000 |> Task.perform (always (CurrentColor color2 color1)) )

        PutBetAmount ->
            case model.rawAmount of
                "0.0" ->
                    ( { model | rawAmount = "" }, Cmd.none )

                "0" ->
                    ( { model | rawAmount = "" }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PutBetAmountAllIn ->
            let
                ethBet =
                    Utils.weiToEther <| model.ethWalletBalance - estimatedGasForBet
            in
            ( { model | rawAmount = String.fromFloat ethBet, amount = ethBet }, Cmd.none )

        FinaliseBetAmount ->
            case String.toFloat model.rawAmount of
                Just amount_ ->
                    let
                        minAmount =
                            0.1

                        maxAmount =
                            Utils.weiToEther model.ethWalletBalance

                        amount =
                            clamp minAmount maxAmount amount_
                    in
                    case model.walletAddress of
                        Nothing ->
                            ( { model | betTypeLabel = "Connect wallet to make a bet" }, Cmd.none )

                        _ ->
                            ( { model | amount = amount, rawAmount = String.fromFloat amount }, Cmd.none )

                Nothing ->
                    ( { model | amount = 0.0, rawAmount = "0.0" }, Cmd.none )

        ChangeBetAmount strAmount ->
            let
                rawAmount =
                    sanitizeFloat strAmount

                amount =
                    Maybe.withDefault 0.1 <| String.toFloat <| rawAmount
            in
            ( { model | rawAmount = rawAmount, amount = amount }, Cmd.none )

        CommitBet Green amount ->
            ( { model | betStatus = InWallet }, Ports.betGreen <| String.fromFloat <| Utils.etherToWei amount )

        CommitBet Blue amount ->
            ( { model | betStatus = InWallet }, Ports.betBlue <| String.fromFloat <| Utils.etherToWei amount )

        BetCommitment 0 ->
            ( { model | betStatus = Pending }, Cmd.none )

        BetCommitment confirmations ->
            if confirmations > 0 then
                ( { model | betStatus = Confirmed, pendingL7lReward = 0 }, Cmd.none )

            else
                ( { model | betStatus = Failed }, Cmd.none )

        DecodeBets betType json ->
            case decodeValue betsDecoder json of
                Ok bets ->
                    case betType of
                        Blue ->
                            ( { model | blueBets = List.reverse bets }, Cmd.none )

                        Green ->
                            ( { model | greenBets = List.reverse bets }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GreenBooty strAmount ->
            case String.toFloat strAmount of
                Just amount ->
                    if amount < model.totalBlueBooty then
                        ( { model | totalGreenBooty = amount, betType = Green }, Cmd.none )

                    else
                        ( { model | totalGreenBooty = amount, betType = Blue }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        BlueBooty strAmount ->
            case String.toFloat strAmount of
                Just amount ->
                    if amount < model.totalGreenBooty then
                        ( { model | totalBlueBooty = amount, betType = Blue }, Cmd.none )

                    else
                        ( { model | totalBlueBooty = amount, betType = Green }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        CurrentRound round ->
            ( { model | currentRound = round }, Cmd.none )

        RoundEndsIn secs ->
            ( { model | roundEndsIn = secs }, Process.sleep 10000 |> Task.perform (always UpdateCountdown) )

        UpdateCountdown ->
            if model.roundEndsIn > 0 then
                ( { model | roundEndsIn = model.roundEndsIn - 10 }, Process.sleep 10000 |> Task.perform (always UpdateCountdown) )
            else
                ( model, Cmd.none )

        LoadHistoryPage historyPage ->
            ( { model | resultsHistoryPage = historyPage }, Ports.resultsHistoryPage historyPage )

        DecodeResultsHistory json ->
            case decodeValue resultsDecoder json of
                Ok results ->
                    ( { model | resultsHistory = results }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        DecodeOutcome json ->
            case decodeValue outcomeDecoder json of
                Ok outcome ->
                    if List.filter (\o -> o.round == outcome.round) model.outcomes == [] then
                        ( { model | outcomes = outcome :: model.outcomes }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        OutcomeClosed outcome ->
            let
                outcomes =
                    List.filter (\o -> o.round /= outcome.round) model.outcomes
            in
            ( { model | outcomes = outcomes }, Ports.resultAcknowledged outcome.block )

        ChainlinkSlide slide ->
            ( { model | currentChainlinkSlide = slide }, Cmd.none )



-- VIEW


pStyles : List (Attribute msg)
pStyles =
    [ Font.size 16
    , Font.center
    ]


hStyles : List (Attribute msg)
hStyles =
    [ Region.heading 2
    , Font.center
    , width fill
    , Font.size 20
    , Font.bold
    ]


view : Model -> Document Msg
view model =
    { title = "L7L Random"
    , body =
        [ column [ centerX, paddingXY 0 <| responsive model.layout 10 20, width fill ] <|
            List.concat
                [ introBlock model
                , if newOutcomeAnnounced model then
                    [ none ]

                  else
                    betsWarning model
                , if newOutcomeAnnounced model then
                    [ none ]

                  else
                    betsBlock model
                , if newOutcomeAnnounced model then
                    [ none ]

                  else
                    contractsBlock model
                , if newOutcomeAnnounced model then
                    [ none ]

                  else
                    levelBlock model
                , if newOutcomeAnnounced model then
                    [ none ]

                  else
                    aboutBlock model
                , if newOutcomeAnnounced model then
                    [ none ]

                  else
                    tokenBlock model
                ]
        ]
    }


introBlock : Model -> List (Element Msg)
introBlock model =
    let
        lead =
            if model.roundEndsIn == -100000 then
                el [ pointer, onClick ConnectWallet ] ( text <| Utils.readableSeconds model.roundEndsIn )
            else
                text <| Utils.readableSeconds model.roundEndsIn

        defaultBlock =
            [ row [ width fill ]
                [ el [ centerX, Config.h1FontSize, Font.color Config.blueColor, Config.mainFont ] <|
                    text "Blue"
                , el [ centerX, Config.h1FontSize, Config.mainFont ] <|
                    text " or "
                , el [ centerX, Config.h1FontSize, Font.color Config.greenColor, Config.mainFont ] <|
                    text "Green"
                , el [ centerX, Config.h1FontSize, Config.mainFont ] <|
                    text "?"
                ]
            , resultsHistory model
            , row [ width fill, paddingXY 0 10 ] <|
                [ column [ centerX ]
                    [ el [ width <| px 150, height <| px 150, Border.rounded 150, Background.color model.currentColor ] <| text ""
                    ]
                ]
            , row [ width fill, Font.size 28, Font.semiBold, Font.underline, paddingXY 0 10 ] <|
                [ column [ centerX ]
                    [ lead
                    ]
                ]
            , row [ width fill, Font.size 12, Font.color Config.grayColor, hidden <| model.roundEndsIn <= 0 ] <|
                [ column [ centerX ]
                    [ text "until Chainlink VRF event"
                    ]
                ]
            , betSelection model
            , estimateRewards model
            , betCommitment model
            , betCommitmentResult model
            ]
    in
    case model.outcomes of
        ({ win, block, amount, round, result, transactionHash } as outcome) :: _ ->
            if round == model.currentRound - 1 then
                let
                    winColor =
                        winColorFromResult result

                    colorStr =
                        if winColor == Config.greenColor then
                            "Green"

                        else if winColor == Config.blueColor then
                            "Blue"

                        else
                            "Refunded"

                    winnerReward =
                        paragraph [ Font.size <| responsive model.layout 10 14, padding 5, Font.center ]
                            [ text <|
                                String.concat
                                    [ "Congratulations! You earned "
                                    , Utils.readableStrEther amount
                                    , " ETH, it's added to your balance along with your bet stake."
                                    ]
                            ]

                    loserReward =
                        paragraph [ Font.size <| responsive model.layout 10 14, padding 5, Font.center ]
                            [ text <|
                                String.concat
                                    [ "No winnings this round. We have added an extra  "
                                    , Utils.readableStrEther amount
                                    , " L7L, as rewards for your next bet."
                                    ]
                            ]
                in
                [ column
                    [ width fill
                    , responsiveColumn model.layout
                    , centerX
                    , padding 15
                    , Background.color Config.blackColor
                    , Font.color Config.whiteColor
                    ]
                    [ row [ width fill, centerX, Font.size <| responsive model.layout 14 20, padding 5 ]
                        [ link [ Font.underline, centerX ]
                            { url = Utils.txUrl model.blockchainExplorer transactionHash
                            , label = text <| String.concat [ "Block #", String.fromInt block ]
                            }
                        , el [ centerX ] <| text " VRF random result: "
                        , el [ centerX, Font.color winColor ] <| text colorStr
                        , el [ alignRight, alignTop, moveUp 10, moveRight 10, pointer, onClick <| OutcomeClosed outcome ] <| text "X"
                        ]
                    , if win then
                        winnerReward

                      else
                        loserReward
                    ]
                ]

            else
                defaultBlock

        _ ->
            defaultBlock


betsWarning : Model -> List (Element Msg)
betsWarning model =
    [ el [ width fill, paddingXY 0 <| if model.walletAddress == Nothing then 0 else 20 ] <|
        column [ width fill, Background.color Config.grayColor ]
            [ textColumn
                [ Font.color Config.whiteColor
                , centerX
                , responsiveColumn model.layout
                , Font.size 12
                , paddingXY 10 20
                ]
                [ paragraph [ width fill, Font.center ] <|
                    [ text <|
                        String.concat
                            [ "Please note: Use at own risk. We don't guarantee equal distribution of stakes in each pool, as such the estimated"
                            , " winnings are an estimate based on the current pool distribution. The L7L fee of 1 % is included in the estimated"
                            , " winnings. We'll close bets for the overbetted side 1 hour before closing to help even out the sides. In our"
                            , " contracts green equals odd, and blue equals even."
                            ]
                    ]
                ]
            ]
    ]


betsBlock : Model -> List (Element Msg)
betsBlock model =
    let
        connectWarning =
            if model.walletAddress == Nothing && model.blueBets == [] && model.greenBets == [] then
                el
                    [ centerX
                    , padding 15
                    , pointer
                    , Font.underline
                    , onClick ConnectWallet
                    ] <| text "Connect to see the bets"
            else
                none
    in
    [ row [ centerX, responsiveColumn model.layout, spacing 40, paddingEach { edges | bottom = 40 }, Font.size <| responsive model.layout 10 14 ]
        [ column [ alignTop, width <| fillPortion 1, paddingEach { edges | left = 10 } ]
            [ el [ centerX, Font.size 20, Font.color Config.blueColor, paddingXY 0 10 ] <| text "Blue"
            , el [ centerX, Font.size 16, paddingXY 10 10 ] <|
                text <|
                    String.concat
                        [ Utils.bulkEther model.totalBlueBooty
                        , " ETH (~"
                        , String.fromInt <| percentShare model.totalBlueBooty model.totalGreenBooty
                        , "%)"
                        ]
            , el [ width fill, Element.inFront connectWarning ] <| totalBets model.blueBets
            ]
        , column [ alignTop, width <| fillPortion 1, paddingEach { edges | right = 10 } ]
            [ el [ centerX, Font.size 20, Font.color Config.greenColor, paddingXY 0 10 ] <| text "Green"
            , el [ centerX, Font.size 16, paddingXY 10 10 ] <|
                text <|
                    String.concat
                        [ Utils.bulkEther model.totalGreenBooty
                        , " ETH (~"
                        , String.fromInt <| percentShare model.totalGreenBooty model.totalBlueBooty
                        , "%)"
                        ]
            , el [ width fill, Element.inFront connectWarning ] <| totalBets model.greenBets
            ]
        ]
    ]


contractsBlock : Model -> List (Element Msg)
contractsBlock model =
    [ column [ width fill, centerX, padding 20, Font.color Config.whiteColor, Background.color Config.blackColor ]
        [ paragraph (padding 5 :: (centerX :: (responsiveColumn model.layout :: pStyles)))
            [ text "→ See the L7L Random contract on "
            , link [ Font.underline ]
                { url = String.concat [ model.blockchainExplorer, "/address/", model.x2ethAddress, "#code" ]
                , label = text "Etherscan"
                }
            ]
        , paragraph (padding 5 :: (centerX :: (responsiveColumn model.layout :: pStyles)))
            [ text "→ See the L7L Random bet logs on "
            , link [ Font.underline ]
                { url = String.concat [ model.blockchainExplorer, "/address/", model.x2ethHistoryAddress, "#events" ]
                , label = text "Etherscan"
                }
            ]
        ]
    ]


levelBlock : Model -> List (Element Msg)
levelBlock model =
    [ column [ width fill, centerX, padding 20, Font.color Config.whiteColor, Background.color Config.highlightColor ]
        [ paragraph ([ responsiveColumn model.layout, padding 10 ] ++ hStyles)
            [ text "LE7EL – pioneering decentralized leverage for mainstream users"
            ]
        , paragraph ([ centerX, padding 10, responsiveColumn model.layout ] ++ pStyles)
            [ text <|
                String.concat
                    [ "LE7EL is the #1 place to access leveraged gaming, trading and betting products for people without professional background,"
                    , " forever 100 % decentralized, permissionless and composable."
                    ]
            ]
        , paragraph ([ centerX, padding 10, responsiveColumn model.layout ] ++ pStyles)
            [ el [ Font.color Config.whiteColor ] <| text "→ "
            , link [ centerX, Font.underline ]
                { url = "https://docs.le7el.com/introduction/le7el-introduction"
                , label = text "Learn more about our vision"
                }
            ]
        ]
    ]


aboutBlock : Model -> List (Element Msg)
aboutBlock model =
    [ textColumn [ width <| px <| responsive model.layout 375 750, paddingEach { edges | top = 20 }, centerX ]
        [ paragraph (padding 10 :: hStyles) [ text "L7L Random – On-chain Verifiable Randomness" ]
        , paragraph (padding 10 :: pStyles)
            [ text <|
                String.concat
                    [ "LE7EL's first product «L7L Random» is the first permissionless, decentralized and verifiable betting protocol"
                    , " made possible by the Chainlink's On-chain "
                    ]
            , link [ Font.underline ]
                { url = "https://docs.chain.link/docs/chainlink-vrf"
                , label = text "Verifiable Random Function (VRF)"
                }
            , text <|
                String.concat
                    [ ". While other solutions trust a central authority or oracle to manage trust, introducing risk of tampering,"
                    , " censorship, fraud and more, «L7L Random» puts the trust in the hands of the science and math of its transparent"
                    , " and auditable contracts."
                    ]
            ]
        , if model.layout.class == Phone then
            ChainlinkSlider.view
                { maxSlide = 4
                , currentSlide = model.currentChainlinkSlide
                , onNextSlide =
                    ChainlinkSlide <|
                        if model.currentChainlinkSlide < 4 then
                            model.currentChainlinkSlide + 1

                        else
                            4
                , onPrevSlide =
                    ChainlinkSlide <|
                        if model.currentChainlinkSlide > 1 then
                            model.currentChainlinkSlide - 1

                        else
                            1
                }

          else
            image [ width fill, height fill, centerX ]
                { src = "./link_all.png"
                , description = "Chainlink VRF flow"
                }
        ]
    ]


tokenBlock : Model -> List (Element Msg)
tokenBlock model =
    [ column [ width fill, centerX, padding 20, Font.color Config.whiteColor, Background.color Config.blackColor ]
        [ paragraph ([ padding 10, responsiveColumn model.layout ] ++ hStyles)
            [ text "LE7EL DAO & Governance"
            ]
        , paragraph ([ centerX, padding 10, responsiveColumn model.layout ] ++ pStyles)
            [ text <|
                String.concat
                    [ "The L7L token is a governance token that also captures the fees for all products built on the L7L protocols."
                    , " It has a fixed supply of 100,000,000 L7L. Holders are able to stake the L7L in the LE7EL DAO and get governance"
                    , " rights and their proportional share of profits in return."
                    ]
            ]
        , paragraph ([ centerX, padding 10, responsiveColumn model.layout ] ++ pStyles)
            [ el [ Font.color Config.whiteColor ] <| text "→ "
            , link [ centerX, Font.underline ]
                { url = "https://docs.le7el.com/about/le7el-dao-and-governance"
                , label = text "Learn more about LE7EL DAO & Governance"
                }
            ]
        ]
    , textColumn [ centerX, width <| px <| responsive model.layout 375 750 ]
        [ paragraph ([ paddingEach { edges | left = 10, right = 10, top = 35, bottom = 20 } ] ++ hStyles)
            [ text "To learn more about LE7EL, our products, DAO, planned token sale and more"
            ]
        , paragraph ([ centerX, padding 10 ] ++ pStyles)
            [ el [ Font.color Config.highlightColor ] <| text "→ "
            , link [ centerX, width <| px 300, Font.alignLeft, Font.underline ]
                { url = "https://docs.le7el.com"
                , label = text "Read our docs"
                }
            ]
        , paragraph ([ centerX, padding 10 ] ++ pStyles)
            [ el [ Font.color Config.highlightColor ] <| text "→ "
            , link [ centerX, width <| px 300, Font.alignLeft, Font.underline ]
                { url = "https://discord.gg/GNevtWkqCw"
                , label = text "Ask questions in our Discord"
                }
            ]
        , paragraph ([ centerX, padding 10 ] ++ pStyles)
            [ el [ Font.color Config.highlightColor ] <| text "→ "
            , link [ centerX, width <| px 300, Font.alignLeft, Font.underline ]
                { url = "https://docs.chain.link/docs/chainlink-vrf"
                , label = text "Learn more about Chainlink VRF"
                }
            ]
        ]
    ]


resultsHistory : Model -> Element Msg
resultsHistory model =
    let
        circlePaddingY =
            responsive model.layout 13 15
            
        arrowPaddingY =
            circlePaddingY + 10

        perPage =
            if model.layout.class == Phone then
                3

            else
                6

        myResult { myBetAmount } winColor =
            if winColor == Config.grayColor then
                "draw"

            else
                case myBetAmount of
                    Just amount ->
                        if String.startsWith "-" amount then
                            "lose"

                        else
                            "win"

                    _ ->
                        ""

        mySaldo { myBetAmount } winColor =
            if winColor == Config.grayColor then
                " "

            else
                case myBetAmount of
                    Just amount ->
                        if String.startsWith "-" amount then
                            String.concat [ "(", Utils.readableStrEther amount, " ETH)" ]

                        else
                            String.concat [ "(+", Utils.readableStrEther amount, " ETH)" ]

                    _ ->
                        " "

        renderResult roundResult =
            let
                winColor =
                    winColorFromResult roundResult.result

                circleSize =
                    responsive model.layout 45 50
            in
            column 
                [ paddingEach { right = 10, left = 10, top = circlePaddingY + 10, bottom = circlePaddingY }
                , centerX
                , Font.size <| responsive model.layout 8 12
                , Font.color winColor
                ]
                [ link [ centerX, width <| px circleSize, height <| px circleSize, Border.rounded circleSize, Background.color winColor ]
                    { url = Utils.txUrl model.blockchainExplorer roundResult.transactionHash
                    , label = text ""
                    }
                , link [ centerX, Font.color Config.grayColor, paddingEach { edges | top = 15 } ]
                    { url = Utils.txUrl model.blockchainExplorer roundResult.transactionHash
                    , label =
                        text <|
                            String.concat
                                [ "#"
                                , String.fromInt roundResult.round
                                , if myResult roundResult winColor /= "" then
                                    " - "

                                  else
                                    ""
                                , myResult roundResult winColor
                                ]
                    }
                , link [ centerX, Font.color Config.grayColor, Font.italic ]
                    { url = Utils.txUrl model.blockchainExplorer roundResult.transactionHash
                    , label = text <| mySaldo roundResult winColor
                    }
                ]

        firstRound =
            case model.resultsHistory of
                first :: _ ->
                    first.round == 1

                _ ->
                    False
    in
    row [ width <| px <| responsive model.layout 375 750, centerX, hidden <| List.length model.resultsHistory == 0 ] <|
        List.concat
            [ [ column [ paddingXY (responsive model.layout 25 40) arrowPaddingY, alignLeft, alignTop ]
                    --, notVisible <| List.length model.resultsHistory < perPage || firstRound ]
                    [ el
                        [ Font.size <| responsive model.layout 40 60
                        , Font.color Config.blackColor
                        , pointer
                        , padding 10
                        , onClick <|
                            LoadHistoryPage <|
                                if List.length model.resultsHistory < perPage || firstRound then
                                    model.resultsHistoryPage

                                else
                                    model.resultsHistoryPage + 1
                        ]
                      <|
                        text "❮"
                    ]
              ]
            , List.map renderResult <| List.sortBy .round model.resultsHistory
            , [ column [ paddingXY (responsive model.layout 25 40) arrowPaddingY, alignRight, alignTop ]
                    --, notVisible <| model.resultsHistoryPage == 1 ]
                    [ el
                        [ Font.size <| responsive model.layout 40 60
                        , Font.color Config.blackColor
                        , pointer
                        , padding 10
                        , onClick <|
                            LoadHistoryPage <|
                                if model.resultsHistoryPage == 1 then
                                    1

                                else
                                    model.resultsHistoryPage - 1
                        ]
                      <|
                        text "❯"
                    ]
              ]
            ]


betSelection : Model -> Element Msg
betSelection model =
    column [ width fill, paddingXY 20 5 ]
        [ row [ width fill ]
            [ column [ centerX ]
                [ Input.radio
                    [ padding 10
                    , spacing 10
                    ]
                    { onChange = ChoseBetType
                    , selected = Just model.betType
                    , label = Input.labelHidden ""
                    , options =
                        [ Input.option Green <| text "Green"
                        , Input.option Blue <| text "Blue"
                        ]
                    }
                ]
            , column [ centerX, width (fill |> maximum 200 |> minimum 100) ]
                [ Input.text
                    [ Font.alignRight
                    , Input.focusedOnLoad
                    , onLoseFocus FinaliseBetAmount
                    , onFocus PutBetAmount
                    ]
                    { onChange = ChangeBetAmount
                    , text = model.rawAmount
                    , label = Input.labelHidden ""
                    , placeholder = Just <| Input.placeholder [] <| text "Enter your bet"
                    }
                ]
            , column [ centerX, centerY ]
                [ el [ alignRight, Font.color Config.grayColor, paddingXY 5 0 ] <| text "ETH"
                ]
            ]
        , row [ width fill, hidden <| model.betTypeLabel == "" ]
            [ column [ width fill ]
                [ el [ Font.color Config.redColor, centerX ] <| text model.betTypeLabel
                ]
            ]
        ]


betCommitment : Model -> Element Msg
betCommitment model =
    row [ width fill, centerX, hidden <| isNoWallet model ]
        [ column [ centerX ]
            [ Components.PlaceBet.view
                { onBet = CommitBet model.betType model.amount
                , disabled = model.betStatus == Pending || model.betStatus == InWallet
                }
            ]
        ]


betCommitmentResult : Model -> Element Msg
betCommitmentResult model =
    let
        renderText fontSize message =
            el [ centerX, Font.size fontSize ] <| text message

        ( messages, color ) =
            case model.betStatus of
                NoBet ->
                    ( [], Font.color Config.blackColor )

                InWallet ->
                    ( [ "Awaiting bet confirmation in your wallet."
                      , " If you are using browser extension and have no popup,"
                      , " please check icon of that browser extension for pending notifications."
                      ]
                    , Font.color Config.blackColor
                    )

                Pending ->
                    ( [ "Awaiting confirmation for your bet from Ethereum blockchain." ]
                    , Font.color Config.blackColor
                    )

                Failed ->
                    ( [ "Your bet has failed, please try again!" ]
                    , Font.color Config.highlightColor
                    )

                Confirmed ->
                    ( [ "Your bet is successfuly placed! L7L is added to your balance." ]
                    , Font.color Config.blackColor
                    )
    in
    row [ width fill, centerX, color, paddingXY 10 0 ]
        [ paragraph
            [ centerX
            , paddingXY 0
                (if messages /= [] then
                    20

                 else
                    0
                )
            , width <| px 350
            , Font.center
            ]
          <|
            List.map (renderText (18 - List.length messages)) messages
        ]


totalBets : List Bet -> Element Msg
totalBets bets =
    let
        renderBet bet =
            row [ width fill, Font.size 10 ]
                [ column [ width fill ] [ el [] <| text <| Utils.shortWallet 6 bet.address ]
                , column [ width fill ] [ el [ alignRight ] <| text <| String.append (Utils.readableStrEther bet.amount) " ETH" ]
                ]
    in
    column
        [ width fill
        , height <| (fill |> maximum 200 |> minimum 50)
        , padding 10
        , spacing 3
        , Border.color Config.grayColor
        , Border.width 1
        , htmlAttribute <| Html.Attributes.style "overflow-y" "auto"
        ]
    <|
        List.map renderBet bets


estimateRewards : Model -> Element Msg
estimateRewards model =
    el [ centerX, paddingXY 0 10 ] <|
        column []
            [ row [ centerX ]
                [ el [ Font.variant Font.smallCaps, Font.color Config.grayColor ] <|
                    text "est. eth prize if won, incl. your bet"
                ]
            , row [ centerX ]
                [ column [ Font.semiBold, Font.size 26 ]
                    [ el [] <| text <| estimateWin model ]
                , column [ Font.semiBold, Font.color Config.grayColor, Font.size 26, paddingXY 0 10 ] [ el [] <| text " ETH" ]

                -- , column [] [ el [] <| text " (87400 USD)" ]
                ]
            , row [ centerX, Font.variant Font.smallCaps, Font.color Config.grayColor ]
                [ text "l"
                , el [ Font.size 15 ] <| text "7"
                , text "l reward, regardless of win or loss"
                ]
            , row [ centerX ]
                [ column [ Font.semiBold, Font.size 26 ]
                    [ el [] <| text <| estimateL7l model ]
                , column [ Font.semiBold, Font.color Config.grayColor, Font.size 26, paddingXY 0 10 ] [ el [] <| text " L7L" ]

                -- , column [] [ el [] <| text " (87400 USD)" ]
                ]
            ]


winColorFromResult : String -> Element.Color
winColorFromResult result =
    let
        color i =
            if i == 0 then
                Config.blueColor

            else if remainderBy 2 i == 0 then
                Config.blueColor

            else
                Config.greenColor
    in
    if result == "0" then
        Config.grayColor

    else
        case String.toInt <| String.right 1 result of
            Just number ->
                color number

            Nothing ->
                Config.grayColor



-- HELPERS


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


sanitizeFloat : String -> String
sanitizeFloat strFloat =
    let
        strip c acc =
            if List.member c [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.' ] then
                if c == '.' && String.contains "." acc then
                    acc

                else
                    String.append (String.fromChar c) acc

            else
                acc

        stripInvalidChars str =
            String.foldr strip "" str
    in
    strFloat
        |> String.replace "," "."
        |> stripInvalidChars


percentShare : Float -> Float -> Int
percentShare num1 num2 =
    if num2 == 0 then
        100

    else
        truncate <| num1 / (num1 + num2) * 100


estimateWin : Model -> String
estimateWin model =
    let
        casinoFeeCorrection =
            0.99

        betAmount =
            Utils.etherToWei model.amount

        totalBooty =
            (model.totalBlueBooty + model.totalGreenBooty + betAmount) * casinoFeeCorrection
    in
    case model.betType of
        Green ->
            Utils.bulkEther <| totalBooty / (model.totalGreenBooty + betAmount) * betAmount

        Blue ->
            Utils.bulkEther <| totalBooty / (model.totalBlueBooty + betAmount) * betAmount


estimateL7l : Model -> String
estimateL7l model =
    let
        betAmount =
            Utils.etherToWei model.amount
    in
    Utils.readableL7l <| betAmount * model.l7lRewardCof + model.pendingL7lReward


betsDecoder : Decoder (List Bet)
betsDecoder =
    list betDecoder


betDecoder : Decoder Bet
betDecoder =
    map2 Bet
        (field "address" string)
        (field "amount" string)


resultsDecoder : Decoder (List RoundResult)
resultsDecoder =
    list <|
        map7 RoundResult
            (field "round" int)
            (field "transactionHash" string)
            (field "result" string)
            (field "totalBooty" string)
            (field "totalWinners" string)
            (field "myBetSide" (nullable string))
            (field "myBetAmount" (nullable string))


outcomeDecoder : Decoder Outcome
outcomeDecoder =
    map7 Outcome
        (field "win" bool)
        (field "block" int)
        (field "transactionHash" string)
        (field "round" int)
        (field "address" string)
        (field "amount" string)
        (field "result" string)


isNoWallet : Model -> Bool
isNoWallet model =
    case model.walletAddress of
        Just _ ->
            False

        Nothing ->
            True


newOutcomeAnnounced : Model -> Bool
newOutcomeAnnounced model =
    case model.outcomes of
        ({ win, block, amount, round, result, transactionHash } as outcome) :: _ ->
            round == model.currentRound - 1

        _ ->
            False


responsiveColumn : Device -> Element.Attribute msg
responsiveColumn layout =
    width <| px <| responsive layout 375 600
