module Pages.Earnl7l exposing (Model, Msg, Params, page)

import Config
import Element exposing (..)
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Region as Region
import Html
import Html.Attributes
import Ports
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Url
import Utils exposing (edges, getBlockchainExplorer, responsive, responsiveAdv)


type alias Params =
    ()


type alias Model =
    { url : Url.Url
    , layout : Device
    , blockchainExplorer : String
    , x2ethAddress : String
    , walletAddress : Maybe String
    }


type Msg
    = ChangeUrl String
    | Never


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
    ( { url = url.rawUrl
      , layout = classifyDevice { height = shared.innerHeight, width = shared.innerWidth }
      , blockchainExplorer = getBlockchainExplorer url.rawUrl.host
      , x2ethAddress = shared.x2ethAddress
      , walletAddress = shared.walletAddress
      }
    , Cmd.none
    )


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { url = shared.url
      , layout = classifyDevice { height = shared.innerHeight, width = shared.innerWidth }
      , blockchainExplorer = getBlockchainExplorer shared.url.host
      , x2ethAddress = shared.x2ethAddress
      , walletAddress = shared.walletAddress
      }
    , Cmd.none
    )


save : Model -> Shared.Model -> Shared.Model
save _ shared =
    shared


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeUrl newUrl ->
            ( model, Ports.pushUrl newUrl )

        Never ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Earning L7L"
    , body =
        [ column [ centerX, Font.size 16, paddingXY 0 20, width fill, spacingXY 0 <| responsive model.layout 0 20 ]
            [ paragraph
                [ responsiveColumn model.layout
                , centerX
                , Region.heading 2
                , Font.center
                , Font.bold
                , Font.size <| responsive model.layout 24 28
                , paddingXY 20 0
                , hidden <| model.layout.class == Phone || model.layout.class == Tablet || model.layout.orientation == Portrait
                ]
                [ el [ alignLeft, pointer, onClick <| ChangeUrl "/" ] (text "❮")
                , text "Earning L7L"
                ]
            , paragraph
                [ responsiveColumn model.layout
                , centerX
                , Font.center
                , paddingEach { top = responsiveAdv model.layout 0 30, bottom = 30, right = 20, left = 20 }
                ]
                [ text "You can earn L7L token two ways: by betting yourself or making others bet through your unique referral link tied to your wallet address" ]
            , paragraph [ responsiveColumn model.layout, centerX, paddingXY 50 0 ]
                [ text "→ All betters earn "
                , el [ Font.bold ] <| text "L7L"
                , text " when they bet, regardless if they win or lose"
                ]
            , paragraph [ responsiveColumn model.layout, centerX, paddingXY 50 0 ]
                [ text "→ You earn "
                , el [ Font.bold ] <| text "1 L7L"
                , text " for each "
                , el [ Font.bold ] <| text "0.1 ETH"
                , text " bet made by everyone using your link ("
                , el [ Font.bold ] <| text "10 ETH"
                , text " in total bets = "
                , el [ Font.bold ] <| text "100 L7L"
                , text ")"
                ]
            , paragraph [ responsiveColumn model.layout, centerX, paddingXY 50 0 ]
                [ text "→ The ones your refer earn extra "
                , el [ Font.bold ] <| text "1 L7L"
                , text " for each "
                , el [ Font.bold ] <| text "0.1 ETH"
                , text " bet they make on top of their existing L7L rewards"
                ]
            , paragraph [ responsiveColumn model.layout, centerX, Font.center, paddingXY 20 30 ]
                [ text <|
                    String.concat
                        [ "This means that this is double incentive program - a win/win for both you and the ones you refer. "
                        , "If you make many people use your link to bet, you could truly earn lots of L7L at a super early-stage."
                        ]
                ]
            , refLinkInput model
            , paragraph [ responsiveColumn model.layout, centerX, Font.center, Font.italic, paddingXY 20 30 ]
                [ text "The rewards will show up in your L7L balance once they are earned."
                ]
            ]
        ]
    }


refLinkInput : Model -> Element msg
refLinkInput ({ url } as model) =
    let
        genLink addr =
            String.concat
                [ Url.toString { url | query = Nothing, path = "", fragment = Nothing }
                , "/?ref="
                , addr
                ]
    in
    case model.walletAddress of
        Just addr ->
            row [ width fill, Font.size <| responsive model.layout 8 14, spacing 5 ]
                [ el
                    [ Font.bold
                    , padding <| responsive model.layout 5 10
                    , centerX
                    , Border.width 1
                    , htmlAttribute <| Html.Attributes.id "ref-link"
                    , htmlAttribute <| Html.Attributes.attribute "data-clipboard-text" <| genLink addr
                    ]
                    (text <| genLink addr)
                , el
                    [ Font.bold
                    , padding <| responsive model.layout 5 10
                    , centerX
                    , Border.width 1
                    , pointer
                    , htmlAttribute <| Html.Attributes.id "ref-link-copy"
                    , htmlAttribute <| Html.Attributes.attribute "data-clipboard-target" "#ref-link"
                    , below <|
                        el
                            [ paddingXY 0 5
                            , htmlAttribute <| Html.Attributes.id "ref-link-copied"
                            , htmlAttribute <| Html.Attributes.style "display" "none"
                            ]
                        <|
                            text "Copied!"
                    ]
                    (text "Copy")
                ]

        Nothing ->
            el [ Font.color Config.redColor, centerX, padding 10 ] <|
                text "You must connect the wallet to generate link"


responsiveColumn : Device -> Element.Attribute msg
responsiveColumn layout =
    width <| (fill |> maximum 1000 |> minimum 375)


hidden : Bool -> Element.Attribute msg
hidden isHidden =
    if isHidden then
        htmlAttribute <| Html.Attributes.style "display" "none"

    else
        htmlAttribute <| Html.Attributes.style "" ""
