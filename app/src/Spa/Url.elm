module Spa.Url exposing (Url, create, defaultUrl)

import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Url


type alias Url params =
    { key : Maybe Key
    , params : params
    , query : Dict String String
    , rawUrl : Url.Url
    }


create : params -> Maybe Key -> Url.Url -> Url params
create params key url =
    { key = key
    , params = params
    , rawUrl = url
    , query =
        url.query
            |> Maybe.map toQueryDict
            |> Maybe.withDefault Dict.empty
    }


toQueryDict : String -> Dict String String
toQueryDict queryString =
    let
        second : List a -> Maybe a
        second =
            List.drop 1 >> List.head

        toTuple : List String -> Maybe ( String, String )
        toTuple list =
            Maybe.map
                (\first ->
                    ( first
                    , second list |> Maybe.withDefault ""
                    )
                )
                (List.head list)

        decode =
            Url.percentDecode >> Maybe.withDefault ""
    in
    queryString
        |> String.split "&"
        |> List.map (String.split "=")
        |> List.filterMap toTuple
        |> List.map (Tuple.mapBoth decode decode)
        |> Dict.fromList


defaultUrl : Url.Protocol -> String -> Maybe Int -> Url.Url
defaultUrl protocol domain prt =
    { protocol = protocol
    , host = domain
    , port_ = prt
    , path = "/"
    , query = Nothing
    , fragment = Nothing
    }
