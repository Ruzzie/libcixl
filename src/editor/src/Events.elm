module Events exposing (..)

{- keyEventDecoder =
       Decode.field "key" Decode.string


   onKeyDown : (String -> msg) -> Attribute msg
   onKeyDown tagger =
       Debug.log "KEY"
           Html.Styled.Events.on
           "keydown"
           (Decode.map tagger keyEventDecoder)



   --Html.Styled.Events.stopPropagationOn "keydown" (Decode.map alwaysPreventDefault (Decode.map tagger keyEventDecoder))



-}
--  "keydown" (Decode.map tagger keyEventDecoder)
-- Html.Styled.Events.custom "KeyDown" (Decode.succeed { message = msg, stopPropagation = True, preventDefault = True })
-- Html.Styled.Events.custom "KeyDown" {keyDecoder}
-- preventDefaultOn "submit" (Decode.map alwaysPreventDefault (Decode.succeed msg))

import Html.Styled exposing (Attribute)
import Html.Styled.Events
import Json.Decode as Decode
import Keyboard.Event exposing (KeyboardEvent, decodeKeyboardEvent)



-- handler with no propagation and default


onKeyDown : (KeyboardEvent -> msg) -> Attribute msg
onKeyDown tag =
    --- https://stackoverflow.com/questions/55554271/elm-how-to-make-custom-event-decoder-to-get-mouse-x-y-position-at-mouse-wheel-mo
    let
        options message =
            { message = message
            , stopPropagation = False
            , preventDefault = True
            }

        decoder =
            decodeKeyboardEvent
                |> Decode.map tag
                |> Decode.map options
    in
    Html.Styled.Events.custom "keydown" decoder



{- Html.Styled.Events.on
   "keydown"
   (Decode.map tagger decodeKeyboardEvent)
-}


always : msg -> ( msg, Bool )
always msg =
    ( msg, True )
