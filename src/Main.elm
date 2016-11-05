module Main exposing (..)

import Html.App
import Html
import Html.Attributes


main : Program Never
main =
    Html.App.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    ()


initialModel : Model
initialModel =
    ()



-- UPDATE


type Msg
    = None


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- VIEW


viewCanvas : Html.Html Msg
viewCanvas =
    Html.div
        [ Html.Attributes.style
            [ ( "width", "250px" )
            , ( "height", "250px" )
            , ( "border", "2px solid black" )
            ]
        ]
        [ Html.div
            [ Html.Attributes.style
                [ ( "height", "250px" )
                , ( "background-image", "url(https://pixabay.com/static/uploads/photo/2015/04/28/13/29/ladybug-743562_640.jpg)" )
                , ( "background-size", "auto 250px" )
                ]
            ]
            []
        ]


view : Model -> Html.Html Msg
view model =
    Html.div
        [ Html.Attributes.style [ ( "padding", "8px" ) ]
        ]
        [ viewCanvas
        , Html.hr [] []
        , Html.text <| toString model
        ]
