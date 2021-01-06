module Utils exposing (bulkEther, bulkEtherRaw, edges, etherToWei, getBlockchainExplorer, readableEther, readableL7l, readableSeconds, readableStrEther, responsive, responsiveAdv, shortWallet, txUrl, weiToEther)

import Element exposing (Device, DeviceClass(..), Orientation(..))


weiToEther : Float -> Float
weiToEther wei =
    wei / 1000000000000000000


etherToWei : Float -> Float
etherToWei ether =
    ether * 1000000000000000000


readableEther : Float -> String
readableEther wei =
    if wei /= 0 then
        let
            ether =
                weiToEther wei
                    |> String.fromFloat

            len =
                String.length ether
        in
        if len > 6 then
            String.dropRight (len - 6) ether

        else
            ether

    else
        "0"


bulkEther : Float -> String
bulkEther wei =
    if wei /= 0 then
        String.append "~" <| bulkEtherRaw wei

    else
        "0"


bulkEtherRaw : Float -> String
bulkEtherRaw wei =
    if wei /= 0 then
        String.fromFloat <| (toFloat <| truncate <| weiToEther wei * 1000.0) / 1000

    else
        "0"


readableStrEther : String -> String
readableStrEther weiStr =
    case String.toFloat weiStr of
        Just wei ->
            readableEther wei

        Nothing ->
            weiStr


readableL7l : Float -> String
readableL7l l7l =
    readableEther l7l


shortWallet : Int -> String -> String
shortWallet left walletAddress =
    if walletAddress == "" then
        walletAddress

    else
        String.concat
            [ String.left left walletAddress
            , "..."
            , String.right 4 walletAddress
            ]


readableSeconds : Int -> String
readableSeconds secs =
    if secs == -100000 then
        "Connect to see countdown"

    else if secs < 30 then
        "asking Chainlink Oracle..."

    else if secs < 60 then
        "less than a minute"

    else if secs >= 60 && secs <= 3600 then
        String.append (String.fromInt <| secs // 60) " minutes"

    else
        let
            hours =
                secs // 3600

            minutes =
                (secs - (hours * 3600)) // 60
        in
        String.concat
            [ String.fromInt hours
            , " hours "
            , String.fromInt minutes
            , " minutes"
            ]


txUrl : String -> String -> String
txUrl explorer hash =
    String.concat [ explorer, "/tx/", hash, "#eventlog" ]


responsive : Device -> Int -> Int -> Int
responsive { class } small big =
    case class of
        Phone ->
            small

        _ ->
            big


responsiveAdv : Device -> Int -> Int -> Int
responsiveAdv { class, orientation } small big =
    case class of
        Phone ->
            small

        Tablet ->
            small

        _ ->
            if orientation == Portrait then
                small

            else
                big


edges : { top : Int, right : Int, bottom : Int, left : Int }
edges =
    { top = 0
    , right = 0
    , bottom = 0
    , left = 0
    }


getBlockchainExplorer : String -> String
getBlockchainExplorer host =
    if host == "le7el.com" then
        "https://etherscan.io"

    else
        "https://rinkeby.etherscan.io"
