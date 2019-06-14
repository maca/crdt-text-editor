import Browser
import Browser.Dom as Dom
import CRDTree exposing
  (CRDTree, Error, add, addAfter, delete, batch)
import CRDTree.Node as Node exposing (Node)
import Html exposing (..)
import Html.Attributes exposing (attribute, style, id, property)
import Html.Events exposing (on)
import Json.Decode as Decode exposing
  (Decoder, at, field, decodeValue)
import Json.Encode as Encode


type alias Model =
  { tree : CRDTree Char }


type Msg
  = EditorChanged (List OperationFunction)


type alias OperationFunction =
  CRDTree Char -> Result (Error Char) (CRDTree Char)


main : Program Decode.Value Model Msg
main =
  Browser.document
    { init = init
    , view = \model ->
        { title = "Editor", body = [view model] }
    , update = update
    , subscriptions = always Sub.none
    }


init flags =
  ( { tree = CRDTree.init { id = 0, maxReplicas = 1024 } }
  , Cmd.none
  )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    EditorChanged funcs ->
      case batch funcs model.tree of
        Ok tree ->
          ( { model | tree = tree }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )


view : Model -> Html Msg
view model =
  Html.node "replicated-editor"
    [ id "crdt-editor"
    , style "width" "100vw"
    , style "height" "100vh"
    , property "content" <| contentEncoder model.tree
    , on "editorChanged" decodeEditorChanged
    ]
    [ ]


decodeEditorChanged : Decoder Msg
decodeEditorChanged =
  Decode.map EditorChanged
    (field "detail" (Decode.list editorOperationDecoder))


editorOperationDecoder : Decoder OperationFunction
editorOperationDecoder =
  (field "op" Decode.string)
    |> Decode.andThen editorOperationDecoderHelp


editorOperationDecoderHelp : String -> Decoder OperationFunction
editorOperationDecoderHelp opType =
  case opType of
    "add" ->
      Decode.map add
        (field "value" charDecoder)

    "addAfter" ->
      Decode.map2 addAfter
        (field "id" <| Decode.list Decode.int)
        (field "value" charDecoder)

    "delete" ->
      Decode.map delete
        (field "id" <| Decode.list Decode.int)

    _ ->
      Decode.fail "Unknown operation"


charDecoder : Decoder Char
charDecoder =
  Decode.string |> Decode.andThen charDecoderHelp


charDecoderHelp : String -> Decoder Char
charDecoderHelp string =
  String.uncons string
    |> Maybe.map (Tuple.first)
    |> Maybe.map Decode.succeed
    |> Maybe.withDefault (Decode.fail "Empty string")


contentEncoder : CRDTree Char -> Encode.Value
contentEncoder tree =
  CRDTree.root tree
    |> Node.children
    |> List.reverse
    |> Encode.list nodeEncoder


nodeEncoder : Node Char -> Encode.Value
nodeEncoder node =
  let
      value =
        Node.value node
          |> Maybe.map String.fromChar
          |> Maybe.withDefault ""
          |> Encode.string
  in
  Encode.object
    [ ( "value", value )
    , ( "id", Node.path node |> Encode.list Encode.int )
    , ( "isDeleted", Node.isDeleted node |> Encode.bool )
    ]


