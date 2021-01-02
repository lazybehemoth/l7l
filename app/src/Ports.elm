port module Ports exposing
    ( betBlue
    , betCommitment
    , betGreen
    , blueBets
    , changeWallet
    , claimEth
    , claimEthState
    , closeEarnL7L
    , connectWallet
    , currentRound
    , externalUrl
    , greenBets
    , notifyResult
    , onUrlChange
    , pushUrl
    , resultAcknowledged
    , resultsHistory
    , resultsHistoryPage
    , roundEndsIn
    , totalBlueBooty
    , totalGreenBooty
    , updateEthBalanceForClaim
    , updateEthWalletBalance
    , updateL7lBalanceForClaim
    , updateL7lReward
    , updatePendingL7lReward
    , walletConnected
    )

import Json.Encode



-- PORTS


port onUrlChange : (String -> msg) -> Sub msg


port pushUrl : String -> Cmd msg


port externalUrl : String -> Cmd msg


port connectWallet : String -> Cmd msg


port changeWallet : String -> Cmd msg


port walletConnected : (String -> msg) -> Sub msg


port updateL7lReward : (Float -> msg) -> Sub msg


port updatePendingL7lReward : (String -> msg) -> Sub msg


port updateEthWalletBalance : (String -> msg) -> Sub msg


port updateEthBalanceForClaim : (String -> msg) -> Sub msg


port updateL7lBalanceForClaim : (String -> msg) -> Sub msg


port betBlue : String -> Cmd msg


port betGreen : String -> Cmd msg


port betCommitment : (Int -> msg) -> Sub msg


port blueBets : (Json.Encode.Value -> msg) -> Sub msg


port greenBets : (Json.Encode.Value -> msg) -> Sub msg


port totalBlueBooty : (String -> msg) -> Sub msg


port totalGreenBooty : (String -> msg) -> Sub msg


port currentRound : (Int -> msg) -> Sub msg


port resultsHistory : (Json.Encode.Value -> msg) -> Sub msg


port resultsHistoryPage : Int -> Cmd msg


port claimEth : String -> Cmd msg


port claimEthState : (Int -> msg) -> Sub msg


port roundEndsIn : (Int -> msg) -> Sub msg


port notifyResult : (Json.Encode.Value -> msg) -> Sub msg


port resultAcknowledged : Int -> Cmd msg


port closeEarnL7L : String -> Cmd msg
