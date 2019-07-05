port module Main exposing (..)


import Browser
import Browser.Dom as Dom
import CRDTree exposing
  (CRDTree, Error, add, addAfter, delete, batch)
import CRDTree.Json exposing (operationEncoder, operationDecoder)
import CRDTree.Node as Node exposing (Node, isDeleted)
import CRDTree.Operation as Operation exposing (Operation)
import Html exposing (..)
import Html.Attributes exposing (attribute, style, id, property)
import Html.Events exposing (on)
import Json.Decode as Decode exposing
  (Decoder, at, field, decodeValue)
import Json.Encode as Encode


port messageOut : Encode.Value -> Cmd msg
port messageIn : (Decode.Value -> msg) -> Sub msg


type alias Model =
  { tree : CRDTree Char
  , selection: Selection
  }


type alias Selection =
  { start: Int
  , end: Int
  , reverse: Bool
  }


type alias OperationFunction =
  CRDTree Char -> Result (Error Char) (CRDTree Char)


type alias Flags =
   { id: Int, maxReplicas: Int }


type Msg
  = EditorChanged (List OperationFunction)
  | SelectionChanged Selection
  | OperationReceived (Operation Char)
  | SyncRequested Int
  | Connected
  | ReplicaOnline ( Int, Int )
  | MessageFail Decode.Error


main : Program Flags Model Msg
main =
  Browser.document
    { init = init
    , view = \model -> { title = "Editor", body = [view model] }
    , update = update
    , subscriptions = subscriptions
    }


init : Flags -> ( Model, Cmd Msg )
init {id, maxReplicas} =
  let
      params =
        { id = id, maxReplicas = maxReplicas }

      model =
        { tree = CRDTree.init params
        , selection = Selection 0 0 False
        }
  in
  ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    EditorChanged funcs ->
      case batch funcs model.tree of
        Ok tree ->
          let
              selection = collapseSelection model.selection
              operation = CRDTree.lastOperation tree
          in
          ( { model | tree = tree, selection = selection }
          , messageOut <| sendOperation operation
          )

        Err _ ->
          ( model, Cmd.none )

    SelectionChanged selection ->
      ( { model | selection = selection }, Cmd.none )

    OperationReceived operation ->
      case CRDTree.apply operation model.tree of
        Ok tree ->
          ( { model | tree = tree }, Cmd.none )

        Err (CRDTree.Error failedOp) ->
          case Operation.replicaId failedOp of
            Just replicaId ->
              ( model
              , messageOut <| syncRequest replicaId model
              )

            Nothing ->
              ( model, Cmd.none )

    SyncRequested timestamp ->
      ( model, messageOut <| sendOperationSince timestamp model )

    Connected ->
      ( model, messageOut <| replicaOnline model )

    ReplicaOnline ( replicaId, timestamp ) ->
      ( model
      , Cmd.batch
          [ messageOut <| syncRequest replicaId model
          , messageOut <| sendOperationSince timestamp model
          ]
      )

    MessageFail error ->
      let
          _ = Debug.log "fail" error
      in
      ( model, Cmd.none )


collapseSelection : Selection -> Selection
collapseSelection {start} =
  Selection start start False


view : Model -> Html Msg
view model =
  viewEditor model


viewEditor : Model -> Html Msg
viewEditor model =
  Html.node "replicated-editor"
    [ id "crdt-editor"
    , style "width" "100vw"
    , style "height" "100vh"
    , property "content" <| contentEncoder model.tree
    , property "selection" <| selectionEncoder model.selection
    , on "editorChanged" editorChangeDecoder
    , on "selectionChanged" <| selectionChangeDecoder model.tree
    ]
    [ ]


editorChangeDecoder : Decoder Msg
editorChangeDecoder =
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
        (field "path" (Decode.list Decode.int))
        (field "value" charDecoder)

    "addAtBeginning" ->
      Decode.map2 addAfter
        (Decode.succeed [0])
        (field "value" charDecoder)

    "delete" ->
      Decode.map delete
        (field "path" <| Decode.list Decode.int)

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


charEncoder : Char -> Encode.Value
charEncoder char =
  String.fromChar char |> Encode.string


contentEncoder : CRDTree Char -> Encode.Value
contentEncoder tree =
  CRDTree.root tree
    |> Node.children
    |> List.filter (\node -> not (isDeleted node))
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
    , ( "path", Node.path node |> Encode.list Encode.int )
    , ( "timestamp", Node.timestamp node |> Encode.int )
    , ( "isDeleted", Node.isDeleted node |> Encode.bool )
    ]


selectionEncoder : Selection -> Encode.Value
selectionEncoder {start, end, reverse} =
  Encode.object
    [ ( "start", Encode.int start )
    , ( "end", Encode.int end )
    , ( "reverse", Encode.bool reverse )
    ]


selectionDecoder : (CRDTree Char) -> Decoder Selection
selectionDecoder tree =
  Decode.map3 Selection
    (field "start" Decode.int)
    (field "end" Decode.int)
    (field "reverse" Decode.bool)


selectionChangeDecoder : (CRDTree Char) -> Decoder Msg
selectionChangeDecoder tree =
  Decode.map SelectionChanged
    (field "detail" (selectionDecoder tree))


subscriptions : Model -> Sub Msg
subscriptions _ =
  messageIn decodeMessage


decodeMessage : Encode.Value -> Msg
decodeMessage value =
  case decodeValue messageDecoder value of
    Ok msg -> msg
    Err str -> MessageFail str


messageDecoder : Decoder Msg
messageDecoder =
  Decode.oneOf
    [ Decode.map OperationReceived <| operationDecoder charDecoder
    , Decode.map SyncRequested <| syncRequestDecoder
    , Decode.map (always Connected) <| connectedDecoder
    , Decode.map ReplicaOnline <| replicaOnlineDecoder
    ]


syncRequest : Int -> Model -> Encode.Value
syncRequest replicaId {tree} =
  let
      timestamp = CRDTree.lastReplicaTimestamp replicaId tree
  in
  Encode.object
    [ ( "last_timestamp", Encode.int timestamp )
    ]


sendOperation : (Operation Char) -> Encode.Value
sendOperation operations =
  operationEncoder charEncoder operations


sendOperationSince : Int -> Model -> Encode.Value
sendOperationSince since {tree} =
  sendOperation <| CRDTree.operationsSince since tree


syncRequestDecoder : Decoder Int
syncRequestDecoder =
  (field "last_timestamp" Decode.int)


replicaOnline : Model -> Encode.Value
replicaOnline {tree} =
  Encode.object
    [ ( "replica_online", Encode.int <| CRDTree.id tree )
    , ( "timestamp", Encode.int <| CRDTree.timestamp tree )
    ]

replicaOnlineDecoder : Decoder ( Int, Int )
replicaOnlineDecoder =
  Decode.map2 Tuple.pair
    (field "replica_online" Decode.int)
    (field "timestamp" Decode.int)


connectedDecoder : Decoder Bool
connectedDecoder =
  (field "connected" Decode.bool)



