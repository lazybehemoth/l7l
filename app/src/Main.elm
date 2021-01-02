module Main exposing (main)

import Browser
import Ports
import Shared exposing (Flags)
import Spa.Document as Document exposing (Document)
import Spa.Generated.Pages as Pages
import Spa.Generated.Route as Route exposing (Route)
import Spa.Url as SpaUrl
import Task
import Url exposing (Url)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view >> Document.toBrowserDocument
        }



-- INIT


type alias Model =
    { shared : Shared.Model
    , page : Pages.Model
    , defaultUrl : Url
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        protocol =
            if flags.https then
                Url.Https

            else
                Url.Http

        defaultUrl =
            SpaUrl.defaultUrl protocol flags.domain (Just flags.http_port)

        url =
            Url.fromString flags.url
                |> Maybe.withDefault defaultUrl
                |> cleanUrl

        ( shared, sharedCmd ) =
            Shared.init flags url

        ( page, pageCmd ) =
            Pages.init (fromUrl url) shared
    in
    ( Model shared page defaultUrl
    , Cmd.batch
        [ send <| UrlChanged url
        , Cmd.map Shared sharedCmd
        , Cmd.map Pages pageCmd
        , Ports.resultsHistoryPage 1
        ]
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | Shared Shared.Msg
    | Pages Pages.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            ( model
            , Ports.pushUrl (Url.toString url)
            )

        LinkClicked (Browser.External href) ->
            ( model
            , Ports.externalUrl href
            )

        UrlChanged url ->
            let
                original =
                    model.shared

                cleanedUrl =
                    cleanUrl url

                shared =
                    { original | url = cleanedUrl }

                ( page, pageCmd ) =
                    Pages.init (fromUrl cleanedUrl) shared
            in
            ( { model | page = page, shared = Pages.save page shared }
            , Cmd.map Pages pageCmd
            )

        Shared sharedMsg ->
            let
                ( shared, sharedCmd ) =
                    Shared.update sharedMsg model.shared

                ( page, pageCmd ) =
                    Pages.load model.page shared
            in
            ( { model | page = page, shared = shared }
            , Cmd.batch
                [ Cmd.map Shared sharedCmd
                , Cmd.map Pages pageCmd
                ]
            )

        Pages pageMsg ->
            let
                ( page, pageCmd ) =
                    Pages.update pageMsg model.page

                shared =
                    Pages.save page model.shared
            in
            ( { model | page = page, shared = shared }
            , Cmd.map Pages pageCmd
            )


view : Model -> Document Msg
view model =
    Shared.view
        { page =
            Pages.view model.page
                |> Document.map Pages
        , toMsg = Shared
        }
        model.shared


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Shared.subscriptions model.shared
            |> Sub.map Shared
        , Pages.subscriptions model.page
            |> Sub.map Pages
        , Ports.onUrlChange (locationHrefToUrl model.defaultUrl >> UrlChanged)
        ]



-- URL


fromUrl : Url -> Route
fromUrl =
    Route.fromUrl >> Maybe.withDefault Route.NotFound


locationHrefToUrl : Url -> String -> Url
locationHrefToUrl defaultUrl locationHref =
    case Url.fromString locationHref of
        Just url ->
            url

        Nothing ->
            defaultUrl


cleanUrl : Url -> Url
cleanUrl url =
    case url.fragment of
        Just fragment ->
            if String.startsWith "/#/" fragment then
                { url | fragment = Nothing, path = String.replace "/#/" "/" fragment }

            else
                url

        _ ->
            url



-- HELPERS


send : msg -> Cmd msg
send msg =
    Task.succeed msg
        |> Task.perform identity
