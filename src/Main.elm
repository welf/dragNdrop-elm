module Main exposing (..)

import Html.App
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (on)
import Json.Decode
import Mouse


-- http://i.imgur.com/4peKJPa.jpg  640x426
-- http://imgur.com/LFWCIHR.jpg  682x454
-- MODEL


type alias Model =
    { canvas : Size
    , borderSize : Int
    , frame : Frame
    , dragState :
        Maybe
            { startPosition : Mouse.Position
            , path : FramePath
            }
    }


type alias Size =
    { width : Int
    , height : Int
    }


type alias Position =
    { x : Int
    , y : Int
    }


type alias Image =
    { url : String
    , imageSize : Size
    , offset : Position
    }


type Frame
    = SingleImage Image
    | HorisontalSplit
        { top : Frame
        , topHeight : Int
        , bottom : Frame
        }


type alias FramePath =
    List Int


initialModel : Model
initialModel =
    { canvas = { width = 250, height = 250 }
    , borderSize = 5
    , frame =
        HorisontalSplit
            { top =
                SingleImage
                    { url = "http://i.imgur.com/4peKJPa.jpg"
                    , imageSize = { width = 640, height = 426 }
                    , offset = { x = 0, y = 0 }
                    }
            , topHeight = 80
            , bottom =
                SingleImage
                    { url = "http://imgur.com/LFWCIHR.jpg"
                    , imageSize = { width = 682, height = 454 }
                    , offset = { x = 0, y = 0 }
                    }
            }
    , dragState = Nothing
    }



-- UPDATE


type Msg
    = DragStart FramePath Mouse.Position
    | DragMove Mouse.Position
    | DragEnd Mouse.Position


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        DragStart path position ->
            ( { model
                | dragState =
                    Just
                        { startPosition = position
                        , path = path
                        }
              }
            , Cmd.none
            )

        DragMove currentPosition ->
            case model.dragState of
                Just { startPosition, path } ->
                    ( { model
                        | dragState =
                            Just
                                { startPosition = currentPosition
                                , path = path
                                }
                        , frame =
                            applyDrag path
                                { x = startPosition.x - currentPosition.x
                                , y = startPosition.y - currentPosition.y
                                }
                                model.frame
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        DragEnd _ ->
            ( { model
                | dragState = Nothing
              }
            , Cmd.none
            )


applyDrag : FramePath -> Position -> Frame -> Frame
applyDrag path changePosition frame =
    case frame of
        SingleImage image ->
            SingleImage
                { image
                    | offset =
                        { x = image.offset.x - changePosition.x
                        , y = image.offset.y - changePosition.y
                        }
                }

        HorisontalSplit { top, topHeight, bottom } ->
            case path of
                [] ->
                    HorisontalSplit
                        { top = top
                        , bottom = bottom
                        , topHeight = topHeight - changePosition.y
                        }

                [ 0 ] ->
                    HorisontalSplit
                        { top = applyDrag path changePosition top
                        , bottom = bottom
                        , topHeight = topHeight
                        }

                _ ->
                    HorisontalSplit
                        { top = top
                        , bottom = applyDrag path changePosition bottom
                        , topHeight = topHeight
                        }



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.div
        [ style [ ( "padding", "8px" ) ] ]
        [ viewCanvas model.borderSize model.canvas model.frame
        , Html.hr [] []
        , Html.text <| toString model
        ]


viewCanvas : Int -> Size -> Frame -> Html Msg
viewCanvas borderSize size frame =
    div
        [ style
            [ ( "width", toString size.width ++ "px" )
            , ( "height", toString size.height ++ "px" )
            , ( "border", "2px solid black" )
            ]
        ]
        [ div
            [ style
                [ ( "border", toString borderSize ++ "px solid " ++ borderColor ) ]
            ]
            [ viewFrame []
                borderSize
                { width = size.width - 2 * borderSize
                , height = size.height - 2 * borderSize
                }
                frame
            ]
        ]


viewFrame : FramePath -> Int -> Size -> Frame -> Html Msg
viewFrame path borderSize size frame =
    case frame of
        SingleImage image ->
            let
                imageRatio =
                    toFloat image.imageSize.width / toFloat image.imageSize.height

                frameRatio =
                    toFloat size.width / toFloat size.height
            in
                div
                    [ style
                        [ ( "height", toString size.height ++ "px" )
                        , ( "background-image"
                          , "url(" ++ image.url ++ ")"
                          )
                        , ( "background-size"
                          , if imageRatio < frameRatio then
                                toString size.width ++ "px auto"
                            else
                                "auto " ++ toString size.height ++ "px"
                          )
                        , ( "cursor", "move" )
                        , ( "background-position"
                          , toString image.offset.x ++ "px " ++ toString image.offset.y ++ "px"
                          )
                        ]
                    , on "mousedown" (Json.Decode.map (DragStart path) Mouse.position)
                    ]
                    []

        HorisontalSplit { top, topHeight, bottom } ->
            div
                []
                [ viewFrame (0 :: path)
                    borderSize
                    { width = size.width
                    , height = topHeight
                    }
                    top
                , div
                    [ style
                        [ ( "width", toString size.width ++ "px" )
                        , ( "height", toString borderSize ++ "px" )
                        , ( "background-color", borderColor )
                        , ( "cursor", "row-resize" )
                        ]
                    , on "mousedown" (Json.Decode.map (DragStart path) Mouse.position)
                    ]
                    []
                , viewFrame (1 :: path)
                    borderSize
                    { width = size.width
                    , height = size.height - topHeight - borderSize
                    }
                    bottom
                ]


borderColor : String
borderColor =
    "tan"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.dragState of
        Just _ ->
            Sub.batch
                [ Mouse.moves DragMove
                , Mouse.ups DragEnd
                ]

        Nothing ->
            Sub.none



-- MAIN


main : Program Never
main =
    Html.App.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
