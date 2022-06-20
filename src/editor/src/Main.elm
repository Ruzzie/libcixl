module Main exposing (..)

{-


   We have a canvas of cixl glyphs (tiles)
   - a cixl (character pixel) is a 8x8 px glyph, yes indeed square ftw. Thus we can 'tile' this
   - we want an editor where we can edit the 'font' definition a 256 character map of 8x8 pixels
   - we want a canvas on which we can 'draw' a selected cixl, with a fg and bg color
   - we also want a fg and color palette editor



   the representation of the 'canvas' (memory mapped textbuffer)
   is [charIdx,fgColorIdx,bgColorIdx]

   - we may consider rotation as additional info, this would deviate from a ascii compatible fontmap, but gain way
     more drawing options


   im not going to optimize the data structures like I would do in C, bitpacking etc.
   This is a purely functional app where we can edit fontmaps,
     color palettes and draw pretty canvases for testing / dev purposes
-}
{-

    TODO [ ] Clear canvas button and or eraser tool
    TODO [ ] Save a Cixl as a data url, such that we can use them as icons in our own application
    TODO [ ] WriteString renders a string in a selected format, (mini cixl buffer) such that we can use our own system font as labels in the app (would be nice)
    TODO  [ ]  Tweak performance of fontmap rendering
    TODO  [ ]  Copy paste
    TODO  [ ]  Drag select
    TODO  [ ]  Draw shapes (rectangle with selected glyphs for corners, lines; line (straight, diagonal))
    TODO  [ ]  Clean up code
    TODO  [ ]  Zoom in / out
    TODO  [ ]  Adjust canvas rows, cols
    TODO  [ ]  Load .ans data (for fun)

   [X]  color palette editor (color pickers)
   [X]  Save , fontmap, canvas, colors
   [X]  Load , fontmap, canvas, colors

-}

import Array exposing (Array)
import Browser
import Browser.Dom as Dom
import Browser.Events
import Cixl exposing (..)
import Css exposing (..)
import Css.Animations exposing (keyframes)
import Dict exposing (Dict)
import Events
import Exports exposing (..)
import File exposing (File)
import File.Download
import File.Select
import Flate
import Graphics.Shapes.Rectangle as Rectangle
import Graphics.Vector2 as Vector2
import Hex
import Html.Events.Extra.Pointer
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, for, id, name, tabindex, title, type_, value)
import Html.Styled.Events
import Html.Styled.Lazy exposing (lazy3, lazy4, lazy5)
import Json.Decode as Decode
import Json.Encode
import Keyboard.Event exposing (KeyboardEvent)
import Keyboard.Key as Key
import PixelFonts
import Serialize as S
import Svg.Styled as Svg
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Events
import Svg.Styled.Lazy
import Task


defaultInitialStatAsCompressedString =
    "AQAABvtVl11oHNcVgE-UrXxJFWkKAk-DkBYxD0sRZWubsA-Lu1a2VIY-JMUtIfRBNmVrg2jdEBIJhkXaOM1fjY3pgx1K6Usg-KnkoZS2oVtUlpS6oZAXtQ0mEIgL7oMhIXZg2cl3zrkzq5zdu_PNmXPPPffcc2dmHxLhKxLsV-RhWujvvbn35o29vnK7_99iv98GJcjWZJK3ElBC0sorlnZaFCEFXT9JWiB6SdumhYvizv6doiiUpb2-t7fuPov9d_r9d_ZNv3Lk0Xw0ykFs-vv7_bSv3UNt9kitNn4ASph75NGvfv75yoqyXMu3Rlv5NWPZ3O5vb4LKs8v95VlQAi4Q95OpSAYy7u-ffxwBme9fP1hdXXnR5kvrKyDWl54WW1gKKiCssuQsMlPMAAjcKToAAstwONSucNYrejYsLJohyFimOZxKSFTE9d1Vfl1CozHh0wDh_K38G7nz5q_OJ2vf_yUoobnR3PjFpW2QvNUqtyGpdzqduvtMuFILznKmlbfOQMohnPQpwiZmpBxTYozYIczgpN7ZBVGk2dqJTNMMJ00mEGsgzWpp3ddaWrW0Vov6eqPR9sGoh3qr0i_VW1npp80AZAJRP2mlh5ZKe72sreI6PzChJeYeJvw4AcZNuALB-QD_1kn5jZs3fxNrD_9tKgUh5ox44lhpVq-XMaCt9MRfL-dobAOY_Vppby5Ln8yqzA9LUSttGo1mo7TBSeWzu3Wm2-2CcHbixNpatCHOKifEw8AgbPolLUvXlz6X6tP8Www-d2JD4lhQtjgHwgx6ZqscN0vYQCC8urrIDgBhXaMY5xIOk2QJlDAckuiahiDhItokuQhiT_1vjSBjE90krHN5qvpUkwUq6wLEmNFX-UfPzEBlTbrH4BzzwISr_DOBqU_dzB6n6AJMbXQBQGXSX_lc7z2zvg4qZyfaZf6Jp8o_8UzHVX3Mv-qn47IAZcy2AKAy5mX-lcv8y_r6M71y3G4jacS1UK765uTf63Y-oeaTeZCdzPpoQ8KHJDdJPgTVfvOaeTdOs3XNPpwPdncHeWgqb8glxH3OJflgvOucZvlMf-CcyZTT2pSTQ3pi292NPulb-aFvxU1GLjmTlJB9XdjuU65NOZNWN497IT3Ec8mks92xG6uO-1j_wHZ86B8c3H5wcBvEPuPxEp8vPZlya27KaQaOvG9rDozcE8VZNQo9NY_2I9VHTvPRcJR7PSwfa243L3o8vTaPEX8ShvFoPLx1-5YuEvvxWHPcvAeydmk-249jPdZs8czyekBf-Z9PwWjTuz6GbSPBH392-z1n9-Ljek_nVNLmJmcI-ZnwbBqCxrMIKGF3d_fXM2EZNL66uFwDdU2ptrLeVruvxGdSEKj7CgTfjKL8gyjKWNhHuZTID2hT5kx5cXHxU9qiMm0MlvwlmxpWkU2UaeND-k9rY8jZCUbwA8E0PLpPZIGjChh8V8C0gnM98hsWaMa0ygb5sg1Wyox7lFbGczTRtxaYtpJwhaPq70dPqi_kfqU_WtrQCj4qqr9f2iCH9U4wDb3HQCu4ZvYcPAIYIU4Ipq0kK7bAxtiV9lVfpOCj18GYQZjGbF3P652JMk1A43tRlBeiKHNZr6tg_8L16y9A8NLjPYp7rAUaJuc2VUC1KXoIqPpm2jzntS3y7d7olr_ziBw_fvykbSq4YB_5vmun7R77UDdVYOtPfCvAvGfu9-6A7Nmvtw_56d24YUPBD-fvfZxrOPDJ4WR4ElLWvvuQ8sQ-KmRDX6PMiPtbjRug79m03qmnYqUYZP5rbCnPOYckuRrnqB0ZHQny_Af6VQntnoZuwvPdbyaIWcaTsDA3N_f_LX--PHl-Y4OjSrjXHGo-VNS-jXDgnT8KnLAUd-_e_cf79Y-ekp1TUpx9-436zuDUJz__5FTrgpx9_6OnBkVd3t7Z2Tl9-jQdEI2dE1Rc4DJGmNKBbnTGBY5wh1NcMwD23-0MNASRvwfpDNSDyD8VfQ6G9hB1tPdbR32KiPwJfNEn9kfFJwGRJ74CPg0Q0COgpVKengHPAyLfOwLaC4h1u-Q3rXcVrwI-xKXrQMTfAhHfAiL-DhD588KRzkvvAiLfeUg6L_0LEPmx4gEgckHRHrfynOL_AJGfKfo6PKvoW-hH-H3Z8_BDtC97Hr6l6Hn4pqLnoQm-6kGeo9urHuQO-JpH9h_-gbz2B0Dkb4pWso4er6HHa-jxGnq8hh6vocdr6PEqvs4RMfTV_Iui27KvOq-7bXdhvmP_SniZUnTbJxR9xs8q-ozPKvqMe4o-4-cUfeUvKFpty08V_Y_WTxS9HnTgy27LvDuX3VaDvOy2hm5r6LVj6LVj6LVj6LVj6LVjaPcHR_vr4-gV9W_wiuf3GIt1xfOr63bF82tazy_4BQ"


lineToCixlBufferEntries : Int -> Int -> Int -> String -> List ( Int, Cixl )
lineToCixlBufferEntries gridWidth xIndent y lineString =
    List.indexedMap
        (\idx char ->
            ( xAndYToIndex gridWidth { x = xIndent + idx, y = y }
            , { glyph = char, fgColorIndex = 1, bgColorIndex = 0 }
            )
        )
        (String.toList lineString)


textToCixlBuffer : Int -> Int -> Int -> String -> CanvasCixlBuffer
textToCixlBuffer indent yStart gridWidth text =
    Dict.fromList <|
        Tuple.second
            (List.foldl
                (\line ( currY, dictEntries ) ->
                    ( currY + 1, lineToCixlBufferEntries gridWidth indent currY line ++ dictEntries )
                )
                ( yStart, [] )
                (String.lines text)
            )


fromCss cssColor =
    ColorDefinition (.red cssColor) (.green cssColor) (.blue cssColor)


bgPalette : ColorPalette
bgPalette =
    Array.fromList
        [ fromCss <| hex "#000000"
        , fromCss <| hex "#494949"
        , fromCss <| hex "#797979"
        , fromCss <| hex "#2000b2"
        , fromCss <| hex "#5182FF"
        , fromCss <| hex "#61D3E3"
        , fromCss <| hex "#386900"
        , fromCss <| hex "#71F341"
        , fromCss <| hex "#8241F3"
        , fromCss <| hex "#9A2079"
        , fromCss <| hex "#FF61B2"
        , fromCss <| hex "#794100"
        , fromCss <| hex "#E35100"
        , fromCss <| hex "#CBD320"
        , fromCss <| hex "#EBEBEB"
        , fromCss <| hex "#FFFFFF"
        ]


fgPalette : ColorPalette
fgPalette =
    Array.fromList <| List.reverse <| Array.toList bgPalette


defaultPalettes =
    { fg = fgPalette, bg = bgPalette }


loadFromPixelFontDefinition : List Int -> List GlyphBitmap
loadFromPixelFontDefinition bytes =
    chunkConcat bytesToGlyphBitmap 8 bytes


defaultFontMap : FontMap
defaultFontMap =
    Array.fromList <| loadFromPixelFontDefinition PixelFonts.tinyType


fantasyFontMap =
    Array.fromList <| loadFromPixelFontDefinition PixelFonts.fantasyType



--- CODECS


bitmapArrayCodec : S.Codec e (Array Bit)
bitmapArrayCodec =
    let
        list : Array Bit -> List Int
        list c =
            chunkConcat (\chunk -> bitsArrayToByte (Array.fromList chunk)) 8 (Array.toList c)
    in
    S.array
        S.byte
        |> S.map
            (\bytes -> Array.fromList (List.concatMap byteToBits (Array.toList bytes)))
            (\bitArray -> Array.fromList <| list bitArray)


glyphBitmapCodec : S.Codec e GlyphBitmap
glyphBitmapCodec =
    S.record GlyphBitmap
        |> S.field .bitmap bitmapArrayCodec
        |> S.finishRecord


fontMapCodec : S.Codec e FontMap
fontMapCodec =
    S.array glyphBitmapCodec


colorDefinitionCodec : S.Codec e ColorDefinition
colorDefinitionCodec =
    S.record ColorDefinition
        |> S.field .red S.byte
        |> S.field .green S.byte
        |> S.field .blue S.byte
        |> S.finishRecord


colorPalettesCodec : S.Codec e ColorPalettes
colorPalettesCodec =
    S.record ColorPalettes
        |> S.field .fg (S.array colorDefinitionCodec)
        |> S.field .bg (S.array colorDefinitionCodec)
        |> S.finishRecord


charByteCodec : S.Codec e Char
charByteCodec =
    S.byte
        |> S.map (\byte -> Char.fromCode byte) (\char -> Char.toCode char)


cixlCodec : S.Codec e Cixl
cixlCodec =
    S.record Cixl
        |> S.field .glyph charByteCodec
        |> S.field .fgColorIndex S.byte
        |> S.field .bgColorIndex S.byte
        |> S.finishRecord


cixlBufferCodec : S.Codec e CanvasCixlBuffer
cixlBufferCodec =
    S.dict S.int cixlCodec


type alias CixlDataWrapper =
    { fontMap : FontMap
    , colorPalettes : ColorPalettes
    , buffer : CanvasCixlBuffer
    }


cixlDataWrapperCodec : S.Codec e CixlDataWrapper
cixlDataWrapperCodec =
    S.record CixlDataWrapper
        |> S.field .fontMap fontMapCodec
        |> S.field .colorPalettes colorPalettesCodec
        |> S.field .buffer cixlBufferCodec
        |> S.finishRecord


saveData : FontMap -> ColorPalettes -> CanvasCixlBuffer -> (S.Codec e CixlDataWrapper -> CixlDataWrapper -> a) -> a
saveData fontMap colorPalettes buffer encodeFormatFunc =
    encodeFormatFunc cixlDataWrapperCodec (CixlDataWrapper fontMap colorPalettes buffer)


saveDataToString : MainModel -> String
saveDataToString mainModel =
    saveData mainModel.fontMap mainModel.currentPalettes mainModel.canvasModel.cixlBuffer S.encodeToString


saveDataToJsonString : MainModel -> String
saveDataToJsonString mainModel =
    Json.Encode.encode 4
        (saveData mainModel.fontMap mainModel.currentPalettes mainModel.canvasModel.cixlBuffer S.encodeToJson)



-- compress


saveToCompressedString : MainModel -> String
saveToCompressedString mainModel =
    -- Maybe.andThen (\bytes -> Just (S.encodeToString S.bytes bytes))
    S.encodeToString S.bytes
        (Flate.deflate
            (saveData mainModel.fontMap mainModel.currentPalettes mainModel.canvasModel.cixlBuffer S.encodeToBytes)
        )


updateMainModelFromCompressedString : MainModel -> String -> MainModel
updateMainModelFromCompressedString modelToUpdate compressedString =
    -- decode the bytes from the string (these are still compressed)
    -- for now we ignore all errors
    case S.decodeFromString S.bytes compressedString of
        Ok bytes ->
            -- decompress the bytes
            case Flate.inflate bytes of
                Just decompressedBytes ->
                    -- decode the bytes to real data
                    case S.decodeFromBytes cixlDataWrapperCodec decompressedBytes of
                        Ok cxlData ->
                            let
                                canvasModel =
                                    modelToUpdate.canvasModel
                            in
                            { modelToUpdate | fontMap = cxlData.fontMap, currentPalettes = cxlData.colorPalettes, canvasModel = { canvasModel | cixlBuffer = cxlData.buffer } }

                        Err _ ->
                            modelToUpdate

                Nothing ->
                    modelToUpdate

        Err _ ->
            modelToUpdate


type alias CellPos =
    { x : Int, y : Int }



-- 1 tile = 8x8 px (real)
-- however we of course want to scale this when needed, especially when editing a glyph
--   maybe that should be the pixel ratio, or is it the 'zoom' where the zoom implementation is to blow up everything by a factor ...?
-- best zooming for svg seems to be done with using the viewport instead of transform
-- lets start with a simple first step
-- render the whole FontMap on the screen scaled 8x up
-- 8 x 8 px square glyphs


glyphSizeInPx =
    8


toRgbString : ColorDefinition -> String
toRgbString color =
    "rgb( " ++ String.fromInt color.red ++ ", " ++ String.fromInt color.green ++ ", " ++ String.fromInt color.blue ++ " )"


drawRawGlyphFromBitmap : List (Svg.Attribute msg) -> ColorPalettes -> Cixl -> Int -> Vector2.Vector2 -> (Int -> List (Svg.Attribute msg)) -> GlyphBitmap -> Svg.Svg msg
drawRawGlyphFromBitmap attrs colorPalettes cixl scaleFactor absScreenPoint extrasPerPixel bitmap =
    let
        fgColor =
            Maybe.withDefault { red = 204, green = 204, blue = 204 } (Array.get cixl.fgColorIndex colorPalettes.fg)

        bgColor =
            Maybe.withDefault { red = 0, green = 0, blue = 0 } (Array.get cixl.bgColorIndex colorPalettes.bg)
    in
    Svg.g attrs <|
        Array.toList <|
            Array.indexedMap
                (\idx bit ->
                    let
                        -- the offset
                        bitRelativeCoord =
                            toVector2 <|
                                indexToXandY glyphSizeInPx idx

                        bitAbsCoord =
                            Vector2.add absScreenPoint (Vector2.multiply { x = toFloat scaleFactor, y = toFloat scaleFactor } bitRelativeCoord)
                    in
                    case bit of
                        One ->
                            toSvgRect
                                (Rectangle.createFromPoint bitAbsCoord
                                    { width = toFloat <| 1 * scaleFactor
                                    , height = toFloat <| 1 * scaleFactor
                                    }
                                )
                                ((SvgAttr.fill <| toRgbString fgColor) :: extrasPerPixel idx)

                        Zero ->
                            toSvgRect
                                (Rectangle.createFromPoint bitAbsCoord
                                    { width = toFloat <| 1 * scaleFactor
                                    , height = toFloat <| 1 * scaleFactor
                                    }
                                )
                                ((SvgAttr.fill <| toRgbString bgColor) :: extrasPerPixel idx)
                )
                bitmap.bitmap


drawRawGlyph attrs fontMap colorPalettes cixl scaleFactor absScreenPoint extrasPerPixel =
    case Array.get (Char.toCode cixl.glyph) fontMap of
        Just glyphBitmap ->
            drawRawGlyphFromBitmap
                attrs
                colorPalettes
                cixl
                scaleFactor
                absScreenPoint
                extrasPerPixel
                glyphBitmap

        Nothing ->
            Svg.g [] []


toVector2 intPoint =
    Vector2.vector2 (toFloat intPoint.x) (toFloat intPoint.y)


indexToXandY rowWidth idx =
    { x = modBy rowWidth idx, y = idx // rowWidth }


xAndYToIndex rowWidth value =
    (value.y * rowWidth) + value.x



--- GENERAL SVG RENDER FUNCTIONS


toSvgRect forRectangle attributes =
    Svg.rect
        (SvgAttr.x (String.fromFloat forRectangle.x)
            :: SvgAttr.y (String.fromFloat forRectangle.y)
            :: SvgAttr.width (String.fromFloat forRectangle.width)
            :: SvgAttr.height (String.fromFloat forRectangle.height)
            :: attributes
        )
        []



--- APP SHIZZLE


type ExportLanguage
    = NoLanguage
    | CSharp
    | C


type alias ExportModel =
    { lang : ExportLanguage
    }


type alias MainModel =
    { fontMap : FontMap
    , fontMapGridScale : Int
    , editorMode : EditorMode
    , canvasModel : CanvasModel
    , glyphToShowInEditor : Char
    , selectedFgIdx : Int
    , selectedBgIdx : Int
    , currentPalettes : ColorPalettes
    , -- the startIdx  in the fontmap from where to start to show 16 shortcuts
      glyphShortcutsStartIdx : Int
    , exportModel : ExportModel
    }


type PaletteType
    = Foreground
    | Background


type UpdateMsg
    = KeyPressed String
    | HandleKeyboardEvent KeyboardEvent
    | HandlePointerDownOnCanvas ( Float, Float )
    | Focus (Result Dom.Error ())
    | HandleToolBarClick ActiveTool
    | UpdateSelectedFgColorIdx Int
    | UpdateSelectedBgColorIdx Int
    | GlyphEditorPixelClicked Int
    | FontMapGlyphClicked Int
    | PaletteColorPickerClicked ( PaletteType, String )
    | ClearCanvasButtonClick
    | SaveEditorStateClick
    | LoadEditorStateClick
    | CxlFileSelected File
    | CxlLoadFromString String
    | ExportModeClicked
    | CanvasModeClicked
    | ExportLanguageClicked ExportLanguage
    | DownloadExportClicked


type alias Cursor =
    { position : CellPos
    }


type alias GridSize =
    { width : Int, height : Int }


type alias CanvasModel =
    { cursor : Cursor
    , gridSizeInTiles : GridSize
    , cixlBuffer : CanvasCixlBuffer
    , scaleFactor : Int
    , currentCanvasTool : ActiveTool
    }


type EditorMode
    = CanvasMode
    | FontMapSelectorMode
    | GlyphEditorMode
    | ExportAsCodeMode


type ActiveTool
    = TypingTool
    | PaintingTool
    | SelectColorTool


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view >> toUnstyled
        }


initialModel : MainModel
initialModel =
    updateMainModelFromCompressedString
        { fontMap = defaultFontMap
        , fontMapGridScale = 3
        , editorMode = CanvasMode
        , canvasModel =
            { cursor = { position = { x = 0, y = 0 } }
            , gridSizeInTiles = { width = 40, height = 30 }
            , cixlBuffer = Dict.empty
            , scaleFactor = 4
            , currentCanvasTool = TypingTool
            }
        , glyphToShowInEditor = Char.fromCode 0
        , selectedFgIdx = 1
        , selectedBgIdx = 0
        , currentPalettes = defaultPalettes
        , glyphShortcutsStartIdx = 0
        , exportModel = { lang = NoLanguage }
        }
        defaultInitialStatAsCompressedString


type NavigationAction
    = MoveUp
    | MoveDown
    | MoveLeft
    | MoveRight
    | MoveToStartOfRow
    | MoveToEndOfRow
    | MoveToStartOfNextLine
    | MoveToPosition CellPos


type CanvasMessage
    = None
    | MoveCanvasCursor NavigationAction
    | PaintTile CellPos
    | SelectTileColors CellPos
    | TypeAction Char
    | Backspace -- dunno a better name
    | NextGlyphShorCutsRow
    | PreviousGlyphShorCutsRow
    | PlaceGlyphFromShortCutIndex Int
    | Delete
    | ClearCanvas


type ExportMessage
    = ShowCodeForLanguage ExportLanguage


type GlyphEditorMessage
    = ToggleBit Int


type ColorPalettesMessage
    = UpdateCurrentSelectedColor ( PaletteType, ColorDefinition )


type EditorModeAction
    = CanvasAction CanvasMessage
    | GlyphEditorAction GlyphEditorMessage
    | ColorPalettesAction ColorPalettesMessage
    | ExportAction ExportMessage
    | Noop


keyToAction key editorMode =
    let
        moveAction =
            case key of
                "ArrowDown" ->
                    Just MoveDown

                "ArrowUp" ->
                    Just MoveUp

                "ArrowLeft" ->
                    Just MoveLeft

                "ArrowRight" ->
                    Just MoveRight

                "Home" ->
                    Just MoveToStartOfRow

                "End" ->
                    Just MoveToEndOfRow

                "Enter" ->
                    Just MoveToStartOfNextLine

                _ ->
                    Nothing
    in
    {- Debug.log key <| -}
    case editorMode of
        CanvasMode ->
            case moveAction of
                Just move ->
                    CanvasAction (MoveCanvasCursor move)

                Nothing ->
                    case String.length key of
                        1 ->
                            -- pattern match on when the list only has one element
                            -- no move could be type action when one char
                            if String.length key == 1 then
                                let
                                    maybeAsciiChar =
                                        Maybe.andThen
                                            (\chr ->
                                                if Char.toCode chr <= 255 then
                                                    Just (TypeAction chr)

                                                else
                                                    Nothing
                                            )
                                            (List.head (String.toList key))
                                in
                                CanvasAction (Maybe.withDefault None maybeAsciiChar)

                            else
                                CanvasAction None

                        _ ->
                            case key of
                                "Backspace" ->
                                    CanvasAction Backspace

                                "Delete" ->
                                    CanvasAction Delete

                                "PageUp" ->
                                    CanvasAction PreviousGlyphShorCutsRow

                                "PageDown" ->
                                    CanvasAction NextGlyphShorCutsRow

                                "F1" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 0)

                                "F2" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 1)

                                "F3" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 2)

                                "F4" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 3)

                                "F5" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 4)

                                "F6" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 5)

                                "F7" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 6)

                                "F8" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 7)

                                "F9" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 8)

                                "F10" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 9)

                                "F11" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 10)

                                "F12" ->
                                    CanvasAction (PlaceGlyphFromShortCutIndex 11)

                                _ ->
                                    CanvasAction None

        _ ->
            Noop


subscriptions : MainModel -> Sub UpdateMsg
subscriptions model =
    Browser.Events.onKeyDown
        keyDecoder


keyDecoder =
    Decode.map KeyPressed (Decode.field "key" Decode.string)


init : () -> ( MainModel, Cmd UpdateMsg )
init _ =
    ( initialModel
    , Task.attempt Focus (Dom.focus "cixlEditor")
    )


update : UpdateMsg -> MainModel -> ( MainModel, Cmd UpdateMsg )
update updateMsg model =
    case updateMsg of
        KeyPressed key ->
            handleAction (keyToAction key model.editorMode) model

        -- ( model, Cmd.none )
        HandleKeyboardEvent keyboardEvent ->
            if keyboardEvent.ctrlKey == False && keyboardEvent.altKey == False && keyboardEvent.keyCode /= Key.Tab then
                ( model, Cmd.none )
                {- case keyboardEvent.key of
                   Just key ->
                       handleAction (keyToAction key model.editorMode) model

                   {- ( model, Cmd.none ) -}
                   Nothing ->
                       ( model, Cmd.none
                -}

            else
                ( model, Cmd.none )

        HandlePointerDownOnCanvas ( clientX, clientY ) ->
            -- convert to tile coordinates
            let
                tileSizeInPx =
                    model.canvasModel.scaleFactor * glyphSizeInPx

                mouseTilePosition =
                    { x = clamp 0 model.canvasModel.gridSizeInTiles.width (Basics.floor <| (clientX / toFloat tileSizeInPx))
                    , y = clamp 0 model.canvasModel.gridSizeInTiles.height (Basics.floor (clientY / toFloat tileSizeInPx))
                    }
            in
            {- Debug.log (Debug.toString ( clientX, clientY, mouseTilePosition )) -}
            case model.editorMode of
                CanvasMode ->
                    -- action depends on the tool, maybe put in a click to action function or something
                    case model.canvasModel.currentCanvasTool of
                        TypingTool ->
                            handleAction
                                (CanvasAction (MoveCanvasCursor (MoveToPosition mouseTilePosition)))
                                model

                        PaintingTool ->
                            handleAction
                                (CanvasAction (PaintTile mouseTilePosition))
                                model

                        SelectColorTool ->
                            handleAction
                                (CanvasAction (SelectTileColors mouseTilePosition))
                                model

                FontMapSelectorMode ->
                    ( model, Cmd.none )

                GlyphEditorMode ->
                    ( model, Cmd.none )

                ExportAsCodeMode ->
                    ( model, Cmd.none )

        UpdateSelectedFgColorIdx fgColorIdx ->
            let
                newIdx =
                    clamp 0 (Array.length model.currentPalettes.fg - 1) fgColorIdx
            in
            ( { model | selectedFgIdx = newIdx }, Cmd.none )

        UpdateSelectedBgColorIdx bgColorIdx ->
            let
                newIdx =
                    clamp 0 (Array.length model.currentPalettes.bg - 1) bgColorIdx
            in
            ( { model | selectedBgIdx = newIdx }, Cmd.none )

        GlyphEditorPixelClicked bitIdx ->
            --Debug.log (Debug.toString updateMsg)
            handleAction
                (GlyphEditorAction (ToggleBit bitIdx))
                model

        FontMapGlyphClicked glyphCode ->
            handleAction (CanvasAction (TypeAction <| Char.fromCode glyphCode)) model

        Focus result ->
            -- don't care
            ( model, Cmd.none )

        HandleToolBarClick clickedTool ->
            case model.editorMode of
                CanvasMode ->
                    let
                        canvasModel =
                            model.canvasModel
                    in
                    ( { model | canvasModel = { canvasModel | currentCanvasTool = clickedTool } }, Cmd.none )

                FontMapSelectorMode ->
                    ( model, Cmd.none )

                GlyphEditorMode ->
                    ( model, Cmd.none )

                ExportAsCodeMode ->
                    ( model, Cmd.none )

        PaletteColorPickerClicked ( paletteType, hexColorString ) ->
            let
                color =
                    --Debug.log hexColorString
                    fromCss (hex hexColorString)
            in
            handleAction (ColorPalettesAction (UpdateCurrentSelectedColor ( paletteType, color ))) model

        ClearCanvasButtonClick ->
            handleAction (CanvasAction ClearCanvas) model

        SaveEditorStateClick ->
            ( model, File.Download.string "cixlEditor.cxl" "text/cxl" (saveToCompressedString model) )

        {- SaveJsonClick ->
           ( model, File.Download.string "cixlEditor.json" "application/json" (saveDataToJsonString model) )
        -}
        LoadEditorStateClick ->
            ( model, File.Select.file [ "text/cxl", "cxl" ] CxlFileSelected )

        CxlFileSelected file ->
            ( model, Task.perform CxlLoadFromString (File.toString file) )

        CxlLoadFromString compressedString ->
            ( updateMainModelFromCompressedString model compressedString, Cmd.none )

        ExportModeClicked ->
            ( { model | editorMode = ExportAsCodeMode }, Cmd.none )

        CanvasModeClicked ->
            ( { model | editorMode = CanvasMode }, Cmd.none )

        ExportLanguageClicked exportLanguage ->
            handleAction (ExportAction (ShowCodeForLanguage exportLanguage)) model

        DownloadExportClicked ->
            case model.exportModel.lang of
                NoLanguage ->
                    ( model, Cmd.none )

                CSharp ->
                    ( model, File.Download.string "CixlData.cs" "text/plain" (exportToCSharp model.fontMap model.currentPalettes) )

                C ->
                    ( model, File.Download.string "cixl-data.h" "text/plain" (exportToC model.fontMap model.currentPalettes) )


handleAction : EditorModeAction -> MainModel -> ( MainModel, Cmd UpdateMsg )
handleAction editorAction model =
    case editorAction of
        CanvasAction msg ->
            case msg of
                None ->
                    ( model, Cmd.none )

                MoveCanvasCursor moveDirection ->
                    let
                        canvasModel =
                            model.canvasModel

                        updatedCursor =
                            moveCursor model.canvasModel.cursor model.canvasModel.gridSizeInTiles moveDirection

                        glyphToShow =
                            -- show the glyph in the glyph editor when the cursor moves to an occupied space
                            Maybe.withDefault model.glyphToShowInEditor (Maybe.map (\cixl -> cixl.glyph) <| Dict.get (xAndYToIndex canvasModel.gridSizeInTiles.width updatedCursor.position) model.canvasModel.cixlBuffer)
                    in
                    ( { model
                        | canvasModel =
                            { canvasModel
                                | cursor = updatedCursor
                            }
                        , glyphToShowInEditor = glyphToShow
                      }
                    , Cmd.none
                    )

                Backspace ->
                    -- delete character 1 position left of cursor (if any) and move cursor left 1
                    let
                        canvasModel =
                            model.canvasModel

                        updatedCursor =
                            moveCursor model.canvasModel.cursor model.canvasModel.gridSizeInTiles MoveLeft

                        indexToDelete =
                            xAndYToIndex model.canvasModel.gridSizeInTiles.width updatedCursor.position
                    in
                    ( { model | canvasModel = { canvasModel | cursor = updatedCursor, cixlBuffer = Dict.remove indexToDelete canvasModel.cixlBuffer } }, Cmd.none )

                Delete ->
                    -- clears the current cursor position
                    let
                        canvasModel =
                            model.canvasModel

                        indexToDelete =
                            xAndYToIndex model.canvasModel.gridSizeInTiles.width model.canvasModel.cursor.position
                    in
                    ( { model | canvasModel = { canvasModel | cixlBuffer = Dict.remove indexToDelete canvasModel.cixlBuffer } }, Cmd.none )

                TypeAction char ->
                    -- put the char on the canvas on the cursor position and move right when you can
                    let
                        canvasModel =
                            model.canvasModel
                    in
                    ( { model
                        | canvasModel =
                            { canvasModel
                                | cursor = moveCursor model.canvasModel.cursor model.canvasModel.gridSizeInTiles MoveRight
                                , cixlBuffer = Dict.insert (xAndYToIndex model.canvasModel.gridSizeInTiles.width model.canvasModel.cursor.position) (Cixl char model.selectedFgIdx model.selectedBgIdx) canvasModel.cixlBuffer
                            }
                        , glyphToShowInEditor = char
                      }
                    , Cmd.none
                    )

                PaintTile tileCoordinate ->
                    -- we are going to paint the target tile
                    let
                        canvasModel =
                            model.canvasModel
                    in
                    ( { model
                        | canvasModel =
                            { canvasModel
                                | cixlBuffer = paintTile canvasModel.cixlBuffer canvasModel.gridSizeInTiles.width tileCoordinate model.selectedFgIdx model.selectedBgIdx
                            }
                      }
                    , Cmd.none
                    )

                SelectTileColors tileCoordinate ->
                    -- set the current selected fg and bg colors to the colors of the selected tile
                    let
                        indexToSelect =
                            xAndYToIndex model.canvasModel.gridSizeInTiles.width tileCoordinate
                    in
                    case Dict.get indexToSelect model.canvasModel.cixlBuffer of
                        Just cixl ->
                            ( { model | selectedFgIdx = cixl.fgColorIndex, selectedBgIdx = cixl.bgColorIndex }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                NextGlyphShorCutsRow ->
                    ( { model | glyphShortcutsStartIdx = modBy 256 (model.glyphShortcutsStartIdx + 16) }, Cmd.none )

                PreviousGlyphShorCutsRow ->
                    ( { model | glyphShortcutsStartIdx = modBy 256 (model.glyphShortcutsStartIdx - 16) }, Cmd.none )

                PlaceGlyphFromShortCutIndex shortCutIndex ->
                    -- put the char on the canvas on the cursor position and move right when you can
                    let
                        canvasModel =
                            model.canvasModel

                        char =
                            Char.fromCode <| model.glyphShortcutsStartIdx + shortCutIndex
                    in
                    ( { model
                        | canvasModel =
                            { canvasModel
                                | cursor = moveCursor model.canvasModel.cursor model.canvasModel.gridSizeInTiles MoveRight
                                , cixlBuffer = Dict.insert (xAndYToIndex model.canvasModel.gridSizeInTiles.width model.canvasModel.cursor.position) (Cixl char model.selectedFgIdx model.selectedBgIdx) canvasModel.cixlBuffer
                            }
                        , glyphToShowInEditor = char
                      }
                    , Cmd.none
                    )

                ClearCanvas ->
                    let
                        canvasModel =
                            model.canvasModel
                    in
                    ( { model | canvasModel = { canvasModel | cixlBuffer = Dict.empty } }, Cmd.none )

        Noop ->
            ( model, Cmd.none )

        GlyphEditorAction glyphEditorMessage ->
            case glyphEditorMessage of
                ToggleBit bitIndex ->
                    -- toggle the selected bit in the fontmap
                    let
                        glyphOption =
                            Array.get (Char.toCode model.glyphToShowInEditor) model.fontMap
                    in
                    case glyphOption of
                        Just glyph ->
                            -- toggle the bit and update the array
                            let
                                updatedGlyphBitmap =
                                    Array.set bitIndex (bitNot (Maybe.withDefault Zero (Array.get bitIndex glyph.bitmap))) glyph.bitmap

                                updatedFontMap =
                                    Array.set
                                        (Char.toCode model.glyphToShowInEditor)
                                        { glyph | bitmap = updatedGlyphBitmap }
                                        model.fontMap
                            in
                            ( { model | fontMap = updatedFontMap }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

        ColorPalettesAction colorPalettesMessage ->
            case colorPalettesMessage of
                UpdateCurrentSelectedColor ( paletteType, colorDefinition ) ->
                    let
                        currentPalettes =
                            -- (Debug.log <| Debug.toString colorDefinition)
                            model.currentPalettes

                        updatedPalettes =
                            case paletteType of
                                Foreground ->
                                    { currentPalettes | fg = Array.set model.selectedFgIdx colorDefinition currentPalettes.fg }

                                Background ->
                                    { currentPalettes | bg = Array.set model.selectedBgIdx colorDefinition currentPalettes.bg }
                    in
                    ( { model | currentPalettes = updatedPalettes }, Cmd.none )

        ExportAction exportMessage ->
            case exportMessage of
                ShowCodeForLanguage language ->
                    let
                        exportModel =
                            model.exportModel
                    in
                    ( { model | exportModel = { exportModel | lang = language } }, Cmd.none )


paintTile : CanvasCixlBuffer -> Int -> CellPos -> Int -> Int -> CanvasCixlBuffer
paintTile cixlBuffer tileGridWidth tileCoordinate selectedFgIdx selectedBgIdx =
    let
        paintWhenPresent maybeCixl =
            case maybeCixl of
                Just cixl ->
                    Just { cixl | fgColorIndex = selectedFgIdx, bgColorIndex = selectedBgIdx }

                Nothing ->
                    Nothing
    in
    Dict.update (xAndYToIndex tileGridWidth tileCoordinate)
        paintWhenPresent
        cixlBuffer


moveCursor : Cursor -> GridSize -> NavigationAction -> Cursor
moveCursor currentCursor gridSizeInTiles direction =
    let
        newPosition =
            case direction of
                MoveUp ->
                    { x = currentCursor.position.x, y = clamp 0 (gridSizeInTiles.height - 1) (currentCursor.position.y - 1) }

                MoveDown ->
                    { x = currentCursor.position.x, y = clamp 0 (gridSizeInTiles.height - 1) (currentCursor.position.y + 1) }

                MoveLeft ->
                    { y = currentCursor.position.y, x = clamp 0 (gridSizeInTiles.width - 1) (currentCursor.position.x - 1) }

                MoveRight ->
                    { y = currentCursor.position.y, x = clamp 0 (gridSizeInTiles.width - 1) (currentCursor.position.x + 1) }

                MoveToStartOfRow ->
                    { y = currentCursor.position.y, x = 0 }

                MoveToEndOfRow ->
                    { y = currentCursor.position.y, x = gridSizeInTiles.width - 1 }

                MoveToStartOfNextLine ->
                    { x = 0, y = clamp 0 (gridSizeInTiles.height - 1) (currentCursor.position.y + 1) }

                MoveToPosition tileCoordinate ->
                    tileCoordinate
    in
    -- (Debug.log <| Debug.toString newPosition)
    { currentCursor | position = newPosition }



--- VIEW FUNCTIONS


defaultTextStyle =
    Css.batch [ fontFamilies [ "Web IBM CGAthin", "monospace" ], fontSize (px 12) ]


view : MainModel -> Html UpdateMsg
view mainModel =
    div
        [ id "cixlEditor" -- overlay to capture extended onkeydown info
        , tabindex 0
        , css [ position absolute, width (pct 100), height (pct 100), overflow hidden, outline none ]
        , Events.onKeyDown HandleKeyboardEvent
        ]
        [ Html.node "style"
            []
            [ text """
                       @font-face {
                         font-family: 'Web IBM CGAthin';
                         font-style: normal;
                         font-weight: 400;
                         src: url(Web437_IBM_CGAthin.woff) format('woff');
                       }
                       button {
                        font-family: 'Web IBM CGAthin';
                        font-weight: bold;
                        height: 24px;
                       }

                       body, pre, p, span {font-family: 'Web IBM CGAthin';}
                       
                       """
            ]
        , div [ css [ displayFlex, defaultTextStyle ] ]
            [ lazy3 renderColorPalettes mainModel.currentPalettes mainModel.selectedFgIdx mainModel.selectedBgIdx
            , renderActionsPanel mainModel.editorMode mainModel.canvasModel.currentCanvasTool
            , case mainModel.editorMode of
                ExportAsCodeMode ->
                    div
                        [ css
                            [ width (px <| toFloat (mainModel.canvasModel.gridSizeInTiles.width * glyphSizeInPx * mainModel.canvasModel.scaleFactor))
                            , height (px <| toFloat (mainModel.canvasModel.gridSizeInTiles.height * glyphSizeInPx * mainModel.canvasModel.scaleFactor))
                            , overflow auto
                            ]
                        ]
                        [ Html.pre [ css [ margin (px 0), backgroundColor (hex "#FEFEFE") ] ]
                            (case mainModel.exportModel.lang of
                                NoLanguage ->
                                    [ text "\n\n\n <-- [SELECT LANGUAGE]" ]

                                CSharp ->
                                    [ text (exportToCSharpUnsafe mainModel.fontMap mainModel.currentPalettes) ]

                                C ->
                                    [ text (exportToC mainModel.fontMap mainModel.currentPalettes) ]
                            )
                        ]

                _ ->
                    lazy3 renderCanvas mainModel.fontMap mainModel.currentPalettes mainModel.canvasModel
            , lazy5 renderShortcutsGlyphSelector
                mainModel.fontMap
                mainModel.currentPalettes
                mainModel.selectedFgIdx
                mainModel.selectedBgIdx
                mainModel.glyphShortcutsStartIdx
            , div
                [ css [ backgroundColor (hex "#efefef") ]
                ]
                [ lazy4
                    renderFontMap
                    mainModel.fontMap
                    mainModel.fontMapGridScale
                    (Char.toCode mainModel.glyphToShowInEditor)
                    mainModel.glyphShortcutsStartIdx
                , renderSelectedGlyphEditor mainModel.fontMap mainModel.currentPalettes mainModel.selectedFgIdx mainModel.selectedBgIdx mainModel.glyphToShowInEditor
                , renderStatusBar mainModel.canvasModel.gridSizeInTiles mainModel.canvasModel.cursor.position (Char.toCode mainModel.glyphToShowInEditor) mainModel.editorMode mainModel.canvasModel.currentCanvasTool
                ]
            ]
        ]


editorModeToString : EditorMode -> String
editorModeToString editorMode =
    case editorMode of
        CanvasMode ->
            "edit mode  "

        FontMapSelectorMode ->
            "select font"

        GlyphEditorMode ->
            "glyph edit"

        ExportAsCodeMode ->
            "export   "


activeToolToString : ActiveTool -> String
activeToolToString activeTool =
    case activeTool of
        TypingTool ->
            "Text tool"

        PaintingTool ->
            "Paint tool"

        SelectColorTool ->
            "Color sel."


renderStatusBar canvasGridSize cursorPos selectedChar editorMode canvasTool =
    div
        [ css [ fontSize (px 12), marginTop (px -3), paddingTop (px 11), paddingBottom (px 8), backgroundColor (rgb 15 15 15), color (rgb 215 215 215), textAlign center ]
        ]
        [ div []
            [ div [ css [ paddingBottom (px 8) ] ] [ text <| String.fromInt selectedChar ++ " - 0x" ++ String.toUpper (Hex.toString selectedChar) ++ " - " ++ String.fromChar (Char.fromCode selectedChar) ]
            , div []
                [ span [ css [ width (ch 12), display inlineBlock ] ] [ text <| editorModeToString editorMode ++ " | " ]
                , span [ css [ width (ch 10), display inlineBlock ] ] [ text <| activeToolToString canvasTool ]
                , span [ css [ width (ch 10), display inlineBlock ] ] [ text <| " | " ++ String.fromInt canvasGridSize.width ++ "x" ++ String.fromInt canvasGridSize.height ++ " | " ]
                , span [ css [ width (ch 5), display inlineBlock ] ] [ text <| String.fromInt cursorPos.y ++ ":" ++ String.fromInt cursorPos.x ]
                ]
            ]
        ]


oneColorPalettes =
    { fg = Array.fromList [ fromCss <| hex "#FFFFFF" ]
    , bg = Array.fromList [ fromCss <| hex "#000000" ]
    }


renderShortcutsGlyphSelector : FontMap -> ColorPalettes -> Int -> Int -> Int -> Html msg
renderShortcutsGlyphSelector fontMap colorPalettes fgColorIndex bgColorIndex glyphStartIdx =
    let
        scaleFactor =
            3
    in
    div
        [ css
            [ displayFlex
            , flexWrap wrap
            , backgroundColor (rgb 150 150 150)
            , alignItems flexStart
            , flexDirection column
            , width (px <| (scaleFactor * glyphSizeInPx) + 4)
            , fontSize (px 8)
            ]
        ]
        ([ div [ css [ marginTop (px 2), marginBottom (px 2), textAlign center, width (px <| (scaleFactor * glyphSizeInPx) + 4) ] ] [ text <| "PgU", hr [] [] ] ]
            ++ (let
                    startIdx =
                        glyphStartIdx

                    shortCutsToShow =
                        Array.slice startIdx (startIdx + 16) fontMap

                    shortCutNumberToKey number =
                        if number <= 12 then
                            "F" ++ String.fromInt number

                        else
                            "C" ++ String.fromInt (number - 12)
                in
                Array.toList <|
                    Array.indexedMap
                        (\glyphIdx glyphBitmap ->
                            div [ css [ width (px <| scaleFactor * glyphSizeInPx), margin (px 2) ] ]
                                [ -- key shortcut
                                  --   glyph
                                  div [ css [ marginTop (px 2), marginBottom (px 1), textAlign center ] ] [ text <| shortCutNumberToKey (modBy 16 glyphIdx + 1) ]
                                , div []
                                    [ Svg.svg
                                        [ SvgAttr.width <| String.fromFloat (glyphSizeInPx * scaleFactor)
                                        , SvgAttr.height <| String.fromFloat (glyphSizeInPx * scaleFactor)
                                        , SvgAttr.viewBox <|
                                            "0 0 "
                                                ++ String.fromFloat glyphSizeInPx
                                                ++ " "
                                                ++ String.fromFloat glyphSizeInPx
                                        ]
                                        [ drawRawGlyphFromBitmap []
                                            colorPalettes
                                            { glyph = Char.fromCode glyphIdx, fgColorIndex = fgColorIndex, bgColorIndex = bgColorIndex }
                                            1
                                            Vector2.zeroVector
                                            (\_ -> [])
                                            glyphBitmap
                                        ]
                                    ]
                                ]
                        )
                        shortCutsToShow
               )
            ++ [ div [ css [ marginTop (px 2), marginBottom (px 2), textAlign center, width (px <| (scaleFactor * glyphSizeInPx) + 4) ] ] [ hr [] [], text <| "PDn" ] ]
        )


renderSelectedGlyphEditor fontMap colorPalettes fgColorIndex bgColorIndex char =
    let
        pixelRatio =
            56
    in
    div
        [ css [ width (px (glyphSizeInPx * pixelRatio)), backgroundColor (rgb 255 255 255) ]
        ]
        [ Svg.svg
            [ SvgAttr.width <| String.fromFloat (glyphSizeInPx * pixelRatio)
            , SvgAttr.height <| String.fromFloat (glyphSizeInPx * pixelRatio)
            , SvgAttr.viewBox <|
                "0 0 "
                    ++ String.fromFloat glyphSizeInPx
                    ++ " "
                    ++ String.fromFloat glyphSizeInPx
            ]
            [ drawRawGlyph [ SvgAttr.stroke "#222222", SvgAttr.strokeWidth "1%", SvgAttr.strokeOpacity "0.3" ]
                fontMap
                colorPalettes
                { glyph = char, fgColorIndex = fgColorIndex, bgColorIndex = bgColorIndex }
                1
                Vector2.zeroVector
                (\bitIndex -> [ css [ cursor crosshair ], Svg.Styled.Events.onClick (GlyphEditorPixelClicked bitIndex) ])
            ]
        ]


actionButton attrs label clickMsg =
    div []
        [ button
            ([ css
                [ fontSize (px 8)
                , width (px 64)
                , backgroundColor (rgb 150 150 150)
                , border3 (px 4) outset (rgb 150 150 150)
                , hover [ border3 (px 4) outset (rgb 250 250 250) ]
                , cursor pointer
                , active
                    [ border3 (px 4) inset (rgb 250 250 250)
                    ]
                , padding (px 0)
                ]
             , Html.Styled.Events.onClick clickMsg
             ]
                ++ attrs
            )
            [ text label ]
        ]


renderActionsPanel : EditorMode -> ActiveTool -> Html UpdateMsg
renderActionsPanel editorMode currentTool =
    let
        hrSeparator =
            hr [ css [ width (px <| (32 * 2) - 2) ] ] []
    in
    div
        [ css
            [ backgroundColor (rgb 50 50 50)
            , Css.property "align-content"
                "flex-start"
            , width (px <| (32 * 2))
            , margin (px 0)
            , borderLeft3 (px 2) inset (rgb 5 5 5)
            ]
        ]
    <|
        case editorMode of
            CanvasMode ->
                [ drawSystemGlyphIconButton 84
                    "Edit mode, shortcut: ctrl q"
                    (currentTool == TypingTool)
                    [ Html.Styled.Attributes.fromUnstyled <| Html.Events.Extra.Pointer.onDown (\_ -> HandleToolBarClick TypingTool) ]
                , drawSystemGlyphIconButton 15
                    "Paint mode, shortcut: ctrl b"
                    (currentTool == PaintingTool)
                    [ Html.Styled.Attributes.fromUnstyled <| Html.Events.Extra.Pointer.onDown (\_ -> HandleToolBarClick PaintingTool) ]
                , drawSystemGlyphIconButton 7
                    "Select colors, shortcut: ctrl w"
                    (currentTool == SelectColorTool)
                    [ Html.Styled.Attributes.fromUnstyled <| Html.Events.Extra.Pointer.onDown (\_ -> HandleToolBarClick SelectColorTool) ]
                , hrSeparator
                , actionButton [ css [ width (pct 50) ], title "clear canvas" ] "CLR" ClearCanvasButtonClick
                , hrSeparator
                , actionButton [] "save" SaveEditorStateClick
                , actionButton [] "export" ExportModeClicked

                {- , actionButton [] "sv json" SaveJsonClick -}
                , actionButton [] "load" LoadEditorStateClick
                ]

            FontMapSelectorMode ->
                []

            GlyphEditorMode ->
                []

            ExportAsCodeMode ->
                [ actionButton [ title "back to editor" ] "<<" CanvasModeClicked
                , hrSeparator
                , actionButton [] ".cs" (ExportLanguageClicked CSharp)
                , actionButton [] ".h" (ExportLanguageClicked C)
                , actionButton [] "save" DownloadExportClicked
                ]


drawSystemGlyphIconButton charCode hint isActive attrs =
    div
        ([ css <|
            [ width (px 24)
            , height (px 24)
            , if isActive then
                border3 (px 4) inset (rgb 255 50 250)

              else
                border3 (px 4) outset (rgb 150 150 150)
            , focus [ border3 (px 4) inset (rgb 250 250 250) ]
            , display inlineBlock
            ]
                ++ (if isActive then
                        [ border3 (px 4) inset (rgb 255 50 250)
                        ]

                    else
                        [ border3 (px 4) outset (rgb 150 150 150)
                        , hover [ border3 (px 4) outset (rgb 250 250 250) ]
                        , cursor pointer
                        , active [ border3 (px 4) inset (rgb 250 250 250) ]
                        ]
                   )
         , title hint
         ]
            ++ attrs
        )
        [ drawSystemGlyphIcon 24 charCode ]


drawSystemGlyphIcon sizeInPx charCode =
    Svg.svg
        [ -- The size on the screen
          SvgAttr.width <| String.fromFloat <| sizeInPx
        , SvgAttr.height <| String.fromFloat <| sizeInPx
        , SvgAttr.viewBox "0 0 8 8" -- zoom with viewport
        ]
        [ drawRawGlyph [] fantasyFontMap defaultPalettes { glyph = Char.fromCode charCode, fgColorIndex = 15, bgColorIndex = 2 } 1 Vector2.zeroVector (\_ -> [])
        ]


colorPaletteColumns =
    4


colorPaletteScaleFactor =
    3


colorPaletteColorBlockSizeInPx =
    colorPaletteScaleFactor * glyphSizeInPx


leftBarWidth =
    colorPaletteColorBlockSizeInPx * colorPaletteColumns


toCssHexString colorDefinition =
    "#" ++ Hex.toString colorDefinition.red ++ Hex.toString colorDefinition.green ++ Hex.toString colorDefinition.blue


renderColorPalettes colorPalettes selectedFgIdx selectedBgIdx =
    let
        selectedFgColorHexStr =
            String.toUpper <|
                toCssHexString (Maybe.withDefault { red = 0, green = 0, blue = 0 } (Array.get selectedFgIdx colorPalettes.fg))

        selectedBgColorHexStr =
            String.toUpper <|
                toCssHexString (Maybe.withDefault { red = 255, green = 255, blue = 255 } (Array.get selectedBgIdx colorPalettes.bg))
    in
    div
        [ css
            [ backgroundColor (rgb 50 50 50)
            , displayFlex
            , flexWrap wrap
            , Css.property "align-content"
                "flex-start"
            , width (px leftBarWidth)
            , margin (px 0)
            ]
        ]
    <|
        -- fg colors
        Array.toList
            (Array.indexedMap
                (\idx color ->
                    div
                        [ css
                            [ width (px colorPaletteColorBlockSizeInPx)
                            , height (px colorPaletteColorBlockSizeInPx)
                            , backgroundColor (rgb color.red color.green color.blue)
                            , cursor pointer
                            ]
                        , Html.Styled.Events.onClick (UpdateSelectedFgColorIdx idx)
                        ]
                        (if idx == selectedFgIdx then
                            [ div
                                [ css
                                    [ borderTop3 (px <| 1.75 * glyphSizeInPx) solid (invertColorForContrast color)
                                    , borderLeft3 (px <| 1.75 * glyphSizeInPx) solid transparent
                                    , borderBottom3 (px <| 1.75 * glyphSizeInPx) solid transparent
                                    , float right
                                    , margin (px 2)
                                    ]
                                ]
                                []
                            ]

                         else
                            []
                        )
                )
                colorPalettes.fg
            )
            ++ [ input
                    [ type_ "color"
                    , id "fgColorPicker"
                    , name "fgColorPicker"
                    , title "Pick a foreground color"
                    , value selectedFgColorHexStr
                    , css
                        [ width (px (leftBarWidth - 4))
                        , margin (px 2)
                        , backgroundColor (rgb 121 121 121)
                        , cursor pointer
                        , border3 (px 2) outset (rgb 150 150 150)
                        ]
                    , Html.Styled.Events.onInput (\hexColorStr -> PaletteColorPickerClicked ( Foreground, hexColorStr ))
                    ]
                    []
               , span [ css [ display inlineBlock, width (px leftBarWidth), textAlign center, color (rgb 215 215 215) ] ] [ text selectedFgColorHexStr ]
               , label
                    [ for "fgColorPicker"
                    , css
                        [ color (rgb 175 175 175)
                        , width (px leftBarWidth)
                        , marginTop (px 4)
                        , textAlign center
                        , fontSize (pct 50)
                        ]
                    ]
                    [ text "^ foreground ^" ]
               ]
            ++ -- separator
               [ hr [ css [ width (px leftBarWidth) ] ] [] ]
            ++ -- bg colors
               Array.toList
                (Array.indexedMap
                    (\idx color ->
                        div
                            [ css <|
                                [ width (px colorPaletteColorBlockSizeInPx)
                                , height (px colorPaletteColorBlockSizeInPx)
                                , backgroundColor (rgb color.red color.green color.blue)
                                , cursor pointer
                                , hover [] -- todo think of something
                                ]
                            , Html.Styled.Events.onClick (UpdateSelectedBgColorIdx idx)
                            ]
                            (if idx == selectedBgIdx then
                                [ div
                                    [ css
                                        [ borderTop3 (px <| 1.75 * glyphSizeInPx) solid (invertColorForContrast color)
                                        , borderLeft3 (px <| 1.75 * glyphSizeInPx) solid transparent
                                        , borderBottom3 (px <| 1.75 * glyphSizeInPx) solid transparent
                                        , float right
                                        , margin (px 2)
                                        ]
                                    ]
                                    []
                                ]

                             else
                                []
                            )
                    )
                    colorPalettes.bg
                )
            ++ [ input
                    [ type_ "color"
                    , id "bgColorPicker"
                    , name "bgColorPicker"
                    , title "Pick a background color"
                    , value selectedBgColorHexStr
                    , css
                        [ width (px (leftBarWidth - 4))
                        , margin (px 2)
                        , backgroundColor (rgb 121 121 121)
                        , cursor pointer
                        , border3 (px 2) outset (rgb 150 150 150)
                        ]
                    , Html.Styled.Events.onInput (\hexColorStr -> PaletteColorPickerClicked ( Background, hexColorStr ))
                    ]
                    []
               , span [ css [ display inlineBlock, width (px leftBarWidth), textAlign center, color (rgb 215 215 215) ] ] [ text selectedBgColorHexStr ]
               , label
                    [ for "bgColorPicker"
                    , css
                        [ color (rgb 175 175 175)
                        , width (px leftBarWidth)
                        , marginTop (px 4)
                        , textAlign center
                        , fontSize (pct 50)
                        ]
                    ]
                    [ text "^ background ^" ]
               ]
            ++ -- separator
               [ hr [ css [ width (px leftBarWidth) ] ] [] ]


invertColorForContrast color =
    rgb (200 - color.red) (200 - color.green) (200 - color.blue)


cursorCssAnimation =
    Css.batch
        [ Css.animationDuration (sec 0.8)
        , Css.animationIterationCount infinite
        , animationName
            (keyframes
                [ ( 0, [ Css.Animations.property "opacity" "0" ] )
                , ( 50, [ Css.Animations.property "opacity" "0.9" ] )
                , ( 100, [ Css.Animations.property "opacity" "0.1" ] )
                ]
            )
        ]


paintSelectToolCursorDataImage =
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAALBJREFUWIXtltEKgCAMRb3h///yetHStaS2pgleiBCJHXaWheAfam3GDgCBSGYAELYeAK0MB9AoaDrtAXDrVJMpFagDYCxA5igXwxUsAPMMgE0WvXxHh3dgATyZAe600v7WuQagOvul08ySKRQ0Y+2I9PTFebVZ+EjFTQRiBzyd88w3A193BKGzc56YipzVnZ3z/H8GvDuSZ+Co4u2cZ/vyH18FAMD8RTMlFad8Fy7X7EsvPkoF7m2hAAAAAElFTkSuQmCC"


renderCanvas : FontMap -> ColorPalettes -> CanvasModel -> Html UpdateMsg
renderCanvas fontMap colorPalettes canvasModel =
    let
        cols =
            canvasModel.gridSizeInTiles.width

        rows =
            canvasModel.gridSizeInTiles.height

        scaleFactor =
            canvasModel.scaleFactor

        showGlyphGrid =
            True

        cursorPos =
            canvasModel.cursor.position
    in
    div
        [ css
            [ width auto
            , backgroundColor (rgb 10 10 10)
            , case canvasModel.currentCanvasTool of
                TypingTool ->
                    hover [ cursor text_ ]

                PaintingTool ->
                    hover [ cursor cell ]

                -- eventually we want to have a todataurl of a cixl, where the svg is serialized, that we can use as cursor
                SelectColorTool ->
                    hover [ property "cursor" ("url(" ++ paintSelectToolCursorDataImage ++ ") 0 32, copy") ]
            ]
        , Html.Styled.Attributes.fromUnstyled
            (Html.Events.Extra.Pointer.onDown (\event -> HandlePointerDownOnCanvas event.pointer.offsetPos))
        ]
        [ Svg.svg
            [ SvgAttr.width <| String.fromInt (cols * glyphSizeInPx * scaleFactor)
            , SvgAttr.height <| String.fromInt (rows * glyphSizeInPx * scaleFactor)
            , SvgAttr.viewBox <|
                "0 0 "
                    ++ String.fromInt (cols * glyphSizeInPx)
                    ++ " "
                    ++ String.fromInt (rows * glyphSizeInPx)
            ]
          <|
            []
                ++ (if showGlyphGrid == True then
                        [ Svg.defs []
                            [ Svg.pattern
                                [ SvgAttr.id "cellGrid"
                                , SvgAttr.width <| String.fromFloat glyphSizeInPx
                                , SvgAttr.height <| String.fromFloat glyphSizeInPx
                                , SvgAttr.patternUnits "userSpaceOnUse"
                                ]
                                [ Svg.rect
                                    [ SvgAttr.width <| String.fromFloat glyphSizeInPx
                                    , SvgAttr.height <| String.fromFloat glyphSizeInPx
                                    , SvgAttr.stroke "gray"
                                    , SvgAttr.strokeWidth "0.5"
                                    , SvgAttr.fill "none"
                                    , SvgAttr.opacity "0.5"
                                    ]
                                    []
                                ]
                            ]
                        , Svg.rect
                            [ SvgAttr.width "100%"
                            , SvgAttr.height "100%"
                            , SvgAttr.fill "url(#cellGrid)"
                            , SvgAttr.opacity "0.5"
                            ]
                            []
                        ]

                    else
                        []
                   )
                ++ renderCanvasTextBuffer fontMap colorPalettes canvasModel.gridSizeInTiles.width canvasModel.cixlBuffer
                ++ [ -- current cursor
                     Svg.Styled.Lazy.lazy2
                        toSvgRect
                        (Rectangle.createFromPoint (Vector2.add { x = 1 / 2, y = 1 / 2 } (tileToScreen cursorPos))
                            { width = glyphSizeInPx - 1, height = glyphSizeInPx - 1 }
                        )
                        [ SvgAttr.fill "none"
                        , SvgAttr.stroke "linen"
                        , SvgAttr.strokeWidth "0.5"
                        , SvgAttr.css
                            [ cursorCssAnimation
                            ]
                        ]
                   ]
        ]


renderCanvasTextBuffer fontMap colorPalettes gridWidthInTiles cixlBuffer =
    Dict.foldr
        (\fontMapIdx cixl acc ->
            -- lazy rendering is slower
            renderCanvasCixl cixl fontMapIdx fontMap colorPalettes gridWidthInTiles
                :: acc
        )
        []
        cixlBuffer


renderCanvasCixl cixl fontMapIdx fontMap colorPalettes gridWidthInTiles =
    Svg.g []
        -- Svg.Styled.Keyed.node "g" | doesnt seem to make much of a difference
        --[]
        [ --( "canvas-" ++ String.fromInt fontMapIdx
          --,
          drawRawGlyph [] fontMap colorPalettes cixl 1 (tileToScreen (indexToXandY gridWidthInTiles fontMapIdx)) (\_ -> [])

        --)
        ]


tileToScreen tileCoord =
    Vector2.scale glyphSizeInPx (toVector2 tileCoord)


{-| a list from 0 to 255
-}
asciiCharCodes =
    List.range 0 255


renderFontMap fontMap fontMapGridScale selectedChar shortCutsSelectedStartIdx =
    -- this is very slow, you notice it when typing, dunno how to do an easy fix now, tried, keyed + lazy ,
    --  should solve this differently
    let
        columns =
            16

        scaleFactor =
            toFloat
                fontMapGridScale
    in
    div
        [ css
            [ backgroundColor (rgb 50 50 50)
            , displayFlex
            , flexWrap wrap
            , width (px (((glyphSizeInPx * scaleFactor) + 2 + 2) * columns))
            , margin (px 0)
            ]
        ]
    <|
        -- todo legend
        List.map
            (renderFontMapGlyphAsSvg fontMap scaleFactor selectedChar shortCutsSelectedStartIdx)
            asciiCharCodes


renderFontMapGlyphAsSvg : Array GlyphBitmap -> Float -> Int -> Int -> Int -> Html UpdateMsg
renderFontMapGlyphAsSvg fontMap scaleFactor selectedChar shortCutsSelectedStartIdx charIdx =
    Svg.svg
        [ -- The size on the screen
          SvgAttr.width <| String.fromFloat <| glyphSizeInPx * scaleFactor
        , SvgAttr.height <| String.fromFloat <| glyphSizeInPx * scaleFactor
        , SvgAttr.viewBox "0 0 8 8" -- zoom with viewport
        , SvgAttr.css
            [ margin (px 1)
            , if charIdx < shortCutsSelectedStartIdx + 16 && charIdx >= shortCutsSelectedStartIdx then
                if charIdx == selectedChar then
                    border3 (px 1) dashed (rgb 255 100 250)

                else
                    border3 (px 1) dashed (rgb 0 200 200)

              else if charIdx == selectedChar then
                border3 (px 1) solid (rgb 255 50 250)

              else
                border3 (px 1) solid (rgb 0 150 0)
            , cursor pointer
            , hover [ border3 (px 1) inset (rgb 0 150 0) ]
            ]
        ]
        [ drawRawGlyph
            [ Svg.Styled.Events.onClick (FontMapGlyphClicked charIdx)
            ]
            fontMap
            oneColorPalettes
            { glyph = Char.fromCode charIdx, fgColorIndex = 1, bgColorIndex = 0 }
            1
            { x = 0, y = 0 }
            (\_ -> [])
        ]
