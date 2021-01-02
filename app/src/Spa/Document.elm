module Spa.Document exposing
    ( Document
    , map
    , toBrowserDocument
    )

import Element exposing (..)
import Html exposing (Html)
import Html.Attributes


type alias Document msg =
    { title : String
    , body : List (Element msg)
    }


map : (msg1 -> msg2) -> Document msg1 -> Document msg2
map fn doc =
    { title = doc.title
    , body = List.map (Element.map fn) doc.body
    }


toBrowserDocument : Document msg -> Html msg
toBrowserDocument doc =
    Element.layout [ width fill, height fill, htmlAttribute <| Html.Attributes.style "overflow-x" "hidden" ]
        (column [ width fill, height fill ] doc.body)
