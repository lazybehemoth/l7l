module Components.Layout.Footer exposing (view)

import Config
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Utils


view : Device -> Element msg
view layout =
    el [ width fill, Region.footer, Border.widthEach { top = 2, bottom = 0, left = 0, right = 0 }, Border.color Config.grayColor ] <|
        row
            [ width <| px <| Utils.responsive layout 375 600
            , centerX
            , Config.mainFont
            , paddingXY 10 30
            ]
            [ column [ width <| fillPortion 1, alignTop, spacing 10, paddingXY 30 20, Font.color Config.grayColor ]
                [ el [ centerX, Font.color Config.blackColor ] <| text "Community"
                , link [ centerX ]
                    { url = "https://discord.gg/GNevtWkqCw"
                    , label = text "Discord"
                    }
                , link [ centerX ]
                    { url = "https://twitter.com/le7el_com"
                    , label = text "Twitter"
                    }
                , link [ centerX ]
                    { url = "https://t.me/le7el_com"
                    , label = text "Telegram"
                    }
                ]
            , column [ width <| fillPortion 1, alignTop, spacing 10, paddingXY 30 20, Font.color Config.grayColor ]
                [ el [ centerX, Font.color Config.blackColor ] <| text "Documentation"
                , link [ centerX ]
                    { url = "https://docs.le7el.com"
                    , label = text "Docs"
                    }
                , link [ centerX ]
                    { url = "https://github.com/le7el/l7l.git"
                    , label = text "Github"
                    }
                , link [ centerX ]
                    { url = "https://medium.com/@le7el"
                    , label = text "Medium"
                    }
                ]
            ]
