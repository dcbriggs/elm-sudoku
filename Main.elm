module Main exposing (..)

import Html exposing (Html, beginnerProgram, button, div, input, text)
import Html.Attributes exposing (attribute, id, style, value)
import Html.Events exposing (onClick, onInput)
import List exposing (all, concatMap, drop, filter, head, length, map, map2, range, repeat, take)
import Maybe
import Result exposing (withDefault)
import Set exposing (diff, fromList, isEmpty, size)
import String exposing (toInt)
import Tuple exposing (second)


width : Int
width =
    9


totalEntryCount : Int
totalEntryCount =
    width * width


type Msg
    = Update Int Int
    | Solve


type alias Model =
    { current : Board
    , nextMoves : List Board
    , valid : Bool
    }


type alias Board =
    List Entry


emptyBoard : Board
emptyBoard =
    map2 (,)
        (range 0 (totalEntryCount - 1))
        (repeat totalEntryCount 0)


model : Model
model =
    { current = emptyBoard
    , nextMoves = nextMoves emptyBoard
    , valid = True
    }



-- let
--     f ( idx, _ ) =
--         ( idx, ((idx // width) + (idx % width)) % 9 + 1 )
-- in
--     map f emptyModel


type alias Entry =
    ( Int, Int )


getFirstEmpty : Board -> Maybe Int
getFirstEmpty model =
    case model of
        [] ->
            Nothing

        ( idx, val ) :: ms ->
            if val == 0 then
                Just idx
            else
                getFirstEmpty ms


allPossibleMoves : Int -> Board -> List Board
allPossibleMoves idx model =
    map (doMove idx model) (range 1 9)


validMove : Int -> Board -> Bool
validMove idx board =
    let
        ss =
            squareAt ( idx, 0 ) board

        cs =
            colAt ( idx, 0 ) board

        rs =
            rowAt ( idx, 0 ) board

        allSets =
            [ ss, cs, rs ]
    in
        all setIsValid allSets


nextMoves : Board -> List Board
nextMoves model =
    case getFirstEmpty model of
        Nothing ->
            []

        Just idx ->
            filter (validMove idx) (allPossibleMoves idx model)


complete : Board -> Bool
complete model =
    let
        nonzero =
            \( idx, val ) -> val /= 0
    in
        all nonzero model


findDone : List Board -> Maybe Board
findDone modelList =
    head (filter complete modelList)


solve : List Board -> Board
solve models =
    case findDone models of
        Nothing ->
            solve (concatMap nextMoves models)

        Just m ->
            m


parseInput : Int -> String -> Msg
parseInput idx string =
    let
        value =
            toInt string
                |> withDefault 0

        f x =
            if x >= 10 then
                f (x - 10)
            else
                x
    in
        Update idx (f value)


entryStyle : Entry -> Model -> List ( String, String )
entryStyle entry model =
    let
        rowIsValid =
            setIsValid (rowAt entry model.current)

        borderTop =
            if rowIsValid then
                "1px solid white"
            else
                "1px solid red"

        colIsValid =
            setIsValid (colAt entry model.current)

        borderLeft =
            if colIsValid then
                "1px solid white"
            else
                "1px solid red"

        sqIsValid =
            setIsValid (squareAt entry model.current)

        background =
            if sqIsValid then
                "white"
            else
                "pink"
    in
        [ ( "border-top", borderTop )
        , ( "border-left", borderLeft )
        , ( "border-right", borderLeft )
        , ( "border-bottom", borderTop )
        , ( "background-color", background )
        ]


showEntry : Model -> Entry -> Html Msg
showEntry model ( idx, int ) =
    input
        [ id ("item-" ++ toString idx)
        , attribute "data-x" (toString (idx // width))
        , attribute "data-y" (toString (idx % width))
        , attribute "data-sq" (toString (squareOf ( idx, int )))
        , value (toString int)
        , style
            ([ ( "width", "1em" )
             , ( "margin", "5px" )
             ]
                ++ (entryStyle ( idx, int ) model)
            )
        , onInput (parseInput idx)
        ]
        []


setsOfGroup : (Entry -> Int) -> Int -> Board -> List Board
setsOfGroup lookup setsLength model =
    map
        (\i ->
            filter
                (\entry ->
                    lookup entry == i
                )
                model
        )
        (range 0 setsLength)


rows : Board -> List Board
rows =
    setsOfGroup rowOf 8


cols : Board -> List Board
cols =
    setsOfGroup colOf 8


squares : Board -> List Board
squares =
    setsOfGroup squareOf 2


containingSet : (Entry -> Int) -> Entry -> List Entry -> List Entry
containingSet f entry model =
    let
        sameSet a =
            f a == f entry
    in
        filter sameSet model


rowAt : Entry -> List Entry -> List Entry
rowAt =
    containingSet rowOf


colAt : Entry -> List Entry -> List Entry
colAt =
    containingSet colOf


squareAt : Entry -> List Entry -> List Entry
squareAt =
    containingSet squareOf


showRow : Model -> List Entry -> Html Msg
showRow model row =
    div [] (map (showEntry model) row)


squareOf : Entry -> Int
squareOf ( idx, _ ) =
    (((idx % 9) // 3) * 3) + (idx // 9) // 3


rowOf : Entry -> Int
rowOf ( idx, _ ) =
    idx % width


colOf : Entry -> Int
colOf ( idx, _ ) =
    idx // width


setIsValid : List Entry -> Bool
setIsValid es =
    let
        nonzero ( idx, val ) =
            val /= 0

        entryList =
            map second (filter nonzero es)

        entrySet =
            fromList entryList
    in
        (size entrySet) == (length entryList)


view : Model -> Html Msg
view model =
    div []
        [ div
            [ style
                [ ( "padding", "3em" )
                , ( "display", "inline-block" )
                ]
            ]
            (map (showRow model) (rows model.current))
        , button [ onClick Solve ] [ text "solve" ]
        ]


updateIndex : Int -> Int -> Entry -> Entry
updateIndex idx value ( i, v ) =
    if i == idx then
        ( i, value )
    else
        ( i, v )


doMove : Int -> Board -> Int -> Board
doMove idx board newValue =
    map (updateIndex idx newValue) board


stepMoves : List Board -> List Board
stepMoves boardList =
    case boardList of
        [] ->
            []

        m :: ms ->
            (nextMoves m) ++ ms


update : Msg -> Model -> Model
update msg model =
    case msg of
        Update idx value ->
            { model | current = doMove idx model.current value }

        Solve ->
            case model.nextMoves of
                [] ->
                    model

                m :: ms ->
                    { model | current = m, nextMoves = stepMoves model.nextMoves }


main : Program Never Model Msg
main =
    beginnerProgram
        { model = model
        , view = view
        , update = update
        }
