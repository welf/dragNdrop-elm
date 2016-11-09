module Main exposing (..)

import Html.App
import Html
import Html.Attributes
import Html.Events
import Json.Decode
import Mouse


-- MODEL


type alias Model =
    { canvas : Size
    , borderSize : Int
    , frame : Frame
    , dragState : Maybe Mouse.Position
    }


type alias Size =
    { width : Int
    , height : Int
    }


type alias Image =
    { url : String
    , size : Size
    }


type Frame
    = SingleImage Image
    | HorisontalSplit
        { top : Frame
        , topHeight : Int
        , bottom : Frame
        }


initialModel : Model
initialModel =
    { canvas = { width = 250, height = 250 }
    , borderSize = 5
    , frame =
        HorisontalSplit
            { top =
                SingleImage
                    { url = "http://i.imgur.com/4peKJPa.jpg"
                    , size = { width = 640, height = 426 }
                    }
            , topHeight = 80
            , bottom =
                SingleImage
                    { url = "http://imgur.com/LFWCIHR.jpg"
                    , size = { width = 682, height = 454 }
                    }
            }
    , dragState = Nothing
    }



-- UPDATE


type Msg
    = DragDividerStart Mouse.Position
    | DragDividerMove Mouse.Position
    | DragDividerEnd Mouse.Position


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        DragDividerStart position ->
            ( { model | dragState = Just position }, Cmd.none )

        DragDividerMove currentPosition ->
            case model.dragState of
                Nothing ->
                    ( model, Cmd.none )

                Just startPosition ->
                    ( { model
                        | frame =
                            applyDrag
                                (currentPosition.y - startPosition.y)
                                model.frame
                        , dragState = Just currentPosition
                      }
                    , Cmd.none
                    )

        DragDividerEnd _ ->
            ( { model | dragState = Nothing }, Cmd.none )


applyDrag : Int -> Frame -> Frame
applyDrag yChange frame =
    case frame of
        SingleImage _ ->
            frame

        HorisontalSplit { top, topHeight, bottom } ->
            HorisontalSplit
                { top = top
                , bottom = bottom
                , topHeight = topHeight + yChange
                }



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.div
        [ Html.Attributes.style [ ( "padding", "8px" ) ]
        ]
        [ viewCanvas model.borderSize model.canvas model.frame
        , Html.hr [] []
        , Html.text <| toString model
        ]


viewCanvas : Int -> Size -> Frame -> Html.Html Msg
viewCanvas borderSize size rootFrame =
    Html.div
        [ Html.Attributes.style
            [ ( "width", toString size.width ++ "px" )
            , ( "height", toString size.height ++ "px" )
            , ( "border", "2px solid black" )
            ]
        ]
        [ Html.div
            [ Html.Attributes.style
                [ ( "border", toString borderSize ++ "px solid " ++ borderColor )
                ]
            ]
            [ viewFrame borderSize
                { width = size.width - 2 * borderSize
                , height = size.height - 2 * borderSize
                }
                rootFrame
            ]
        ]


viewFrame : Int -> Size -> Frame -> Html.Html Msg
viewFrame borderSize size frame =
    case frame of
        SingleImage image ->
            let
                imageRatio =
                    toFloat image.size.width / toFloat image.size.height

                frameRatio =
                    toFloat size.width / toFloat size.height
            in
                Html.div
                    [ Html.Attributes.style
                        [ ( "height", toString size.height ++ "px" )
                        , ( "background-image", "url(" ++ image.url ++ ")" )
                        , ( "background-size"
                          , if imageRatio > frameRatio then
                                "auto " ++ toString size.height ++ "px"
                            else
                                toString size.width ++ "px auto"
                          )
                        ]
                    ]
                    []

        HorisontalSplit { top, topHeight, bottom } ->
            Html.div []
                [ viewFrame borderSize
                    { width = size.width
                    , height = topHeight
                    }
                    top
                , Html.div
                    [ Html.Attributes.style
                        [ ( "width", toString size.width ++ "px" )
                        , ( "height", toString borderSize ++ "px" )
                        , ( "background-color", borderColor )
                        , ( "cursor", "row-resize" )
                        ]
                    , Html.Events.on "mousedown" (Json.Decode.map DragDividerStart Mouse.position)
                    ]
                    []
                , viewFrame borderSize
                    { width = size.width
                    , height =
                        size.height - topHeight - borderSize
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
        Nothing ->
            Sub.none

        Just _ ->
            Sub.batch
                [ Mouse.moves DragDividerMove
                , Mouse.ups DragDividerEnd
                ]



-- MAIN


main : Program Never
main =
    Html.App.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
