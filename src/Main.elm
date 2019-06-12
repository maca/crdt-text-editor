import Browser
import Browser.Dom as Dom
import CRDTree exposing (CRDTree, add)
import Html exposing (..)
import Html.Attributes exposing (attribute, style, id, property)
import Json.Decode as Decode exposing (Decoder, decodeValue)



type alias Model =
  { tree : CRDTree Char }


type Msg = Msg


main : Program Decode.Value Model Msg
main =
  Browser.document
    { init = init
    , view = \model -> { title = "Editor", body = [view model] }
    , update = update
    , subscriptions = always Sub.none
    }


init flags =
  let
      tree =
        CRDTree.init { id = 0, maxReplicas = 1024 }

      tree2 =
        add 'a' tree
          |> Result.andThen (add 'b')
          |> Result.andThen (add 'c')
          |> Result.andThen (add 'd')
          |> Result.andThen (add 'b')
          |> Result.withDefault tree
  in
  ( { tree = tree2 }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  ( model, Cmd.none )


view : Model -> Html Msg
view model =
  div [] [ text "" ]


