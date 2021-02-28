module Main exposing (..)

import Browser
import Html exposing (Html, text, div)
import Bootstrap.Button as Button
import Html.Events exposing (onClick)
import Html.Attributes exposing (src, style)
import Ports
import Json.Decode as Decode
import Json.Encode as Encode
import Time as Time
import Task
import DateFormat as Format
import List as List
import Debug as Debug
import TimeZone as TimeZone


---- MODEL ----


type alias Model = { events : List String, timeZone: Time.Zone }


init : Maybe String -> ( Model, Cmd Msg )
init model =
    let 
        initEvents = 
            case model of
                Just m -> 
                    case Decode.decodeString (Decode.list Decode.string) m of
                        Ok events -> events
                        _ -> []
                Nothing -> []
    in 
        ( { events = initEvents, timeZone = Time.utc }
        , TimeZone.getZone |> Task.attempt ReceiveTimeZone 
        )



---- UPDATE ----


type Msg
    = NoOp
    | AtTime String
    | OnTime String Time.Posix
    | ReceiveTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | DeleteLast


atTime : String -> Cmd Msg
atTime m = Task.perform (OnTime m) Time.now

formatTime : Time.Zone -> Time.Posix -> String
formatTime = 
    Format.format "MM/dd HH:mm" 

tail : List a -> List a
tail arg = 
    case arg of
       x::xs -> xs
       x -> []



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AtTime message -> ( model, atTime message )
        OnTime message time -> 
            let
                newModel = 
                    { model | events = (message ++ (formatTime model.timeZone time)) :: model.events}
            in
                (newModel, saveEvents newModel.events)
        DeleteLast -> 
            let
                newModel = 
                    { model | events = (tail model.events)}
            in
                (newModel, saveEvents newModel.events)
        ReceiveTimeZone res ->
            case res of
                Ok (str, zon) -> ({ model | timeZone = zon }, Cmd.none )
                Err error -> ({ model | timeZone = Time.utc }, Cmd.none )
        _ -> ( model, Cmd.none )


saveEvents : List String -> Cmd msg
saveEvents events =
    Encode.encode 0 (Encode.list Encode.string events)
        |> Ports.storeEvents



---- VIEW ----

viewEvent : String -> Html Msg
viewEvent msg = 
    div [] [ text msg ]

view : Model -> Browser.Document Msg
view model =
    { title = "Islog"
    , body = [
        div [] [ 
            div 
              [ style "display" "flex"
              , style "flex-wrap" "wrap" 
              , style "justify-content" "space-evenly"
              , style "padding" "10px"] 
            [ Button.button 
              [ Button.large, Button.primary
              , Button.attrs [ onClick (AtTime "Foodered the bebe. ") ] ] 
              [ text "Feed" ]
            , Button.button 
              [ Button.large, Button.primary
              , Button.attrs [ onClick (AtTime "The bebe is nappin. ") ] ] 
              [ text "Start Nap" ]
            , Button.button 
              [ Button.large, Button.primary
              , Button.attrs [ onClick (AtTime "The bebe is not nappin. ") ] ] 
              [ text "End Nap" ]
            , Button.button 
              [ Button.large, Button.danger
              , Button.attrs [ onClick DeleteLast ] ] 
              [ text "Oops" ]
            ]
        , div [] (List.map viewEvent model.events)
        ]
    ]
    }



---- PROGRAM ----


main : Program (Maybe String) Model Msg
main =
    Browser.document
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }
