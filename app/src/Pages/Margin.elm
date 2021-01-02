module Pages.Margin exposing (Model, Msg, Params, page)

import Element exposing (..)
import Element.Font as Font
import Element.Region as Region
import Shared
import Spa.Document exposing (Document)
import Spa.Page as Page exposing (Page)
import Spa.Url exposing (Url)
import Utils exposing (edges, getBlockchainExplorer, responsive)


type alias Params =
    ()


type alias Model =
    { layout : Device
    , blockchainExplorer : String
    , x2ethAddress : String
    , walletAddress : Maybe String
    }


type alias Msg =
    Never


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
      , walletAddress = shared.walletAddress
      }
    , Cmd.none
    )


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    ( { layout = classifyDevice { height = shared.innerHeight, width = shared.innerWidth }
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
    ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    { title = "L7L Margin"
    , body =
        [ column [ centerX, paddingXY 0 20, width fill, spacingXY 0 20 ]
            [ paragraph [ centerX, Region.heading 2, Font.center, Font.bold, Font.size <| responsive model.layout 24 28, paddingXY 20 0 ]
                [ text "L7L Margin - complex margin products made easy" ]
            , paragraph [ centerX, Font.center, paddingEach { left = 20, right = 20, top = 10, bottom = responsive model.layout 40 250 } ]
                [ text "A new generation of margin products are coming soon - stay tuned!" ]
            ]
        ]
    }
