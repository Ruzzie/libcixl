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

    TODO  [ ]  Save , fontmap, canvas, colors
    TODO  [ ]  Load , fontmap, canvas, colors
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

-}

import Array exposing (Array)
import Bitwise
import Browser
import Browser.Dom as Dom
import Browser.Events
import Bytes.Encode
import Css exposing (..)
import Css.Animations exposing (keyframes)
import Dict exposing (Dict)
import Events
import Graphics.Shapes.Rectangle as Rectangle
import Graphics.Vector2 as Vector2
import Hex
import Html.Events.Extra.Pointer
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, for, id, name, tabindex, title, type_, value)
import Html.Styled.Events
import Html.Styled.Lazy exposing (lazy3, lazy5)
import Json.Decode as Decode
import Keyboard.Event exposing (KeyboardEvent)
import Keyboard.Key exposing (Key(..))
import PixelFonts
import Svg.Styled as Svg
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Events
import Svg.Styled.Keyed
import Svg.Styled.Lazy
import Task


defaultText =
    """
ÉÍÍÍÍ»
ºCIXLº
ÈÍÍÍÍ¼
"""


lineToCixlBufferEntries : Int -> Int -> Int -> String -> List ( Int, Cixl )
lineToCixlBufferEntries gridWidth xIndent y line =
    List.indexedMap
        (\x char ->
            ( xAndYToIndex gridWidth { x = xIndent + x, y = y }
            , { glyph = char, fgColorIndex = 1, bgColorIndex = 0 }
            )
        )
        (String.toList line)


textToCixlBuffer : { a | x : Int, y : Int } -> Int -> String -> CanvasCixlBuffer
textToCixlBuffer offset gridWidth text =
    Dict.fromList <|
        Tuple.second
            (List.foldl
                (\line ( currY, dictEntries ) ->
                    ( currY + 1, lineToCixlBufferEntries gridWidth offset.x currY line ++ dictEntries )
                )
                ( offset.y, [] )
                (String.lines text)
            )



-- ELM FORMAT CANNOT HANDLE ANSI ESCAPE CODES IN DECLARED STRING
{-
   TODO MAP .ANS TO GRID
   ansiColorToColorIndex : Maybe Ansi.Color -> unknown
   ansiColorToColorIndex ansiColor =



   ansiLineToCixlBufferEntries : Int -> Ansi.Log.Line -> List (Int, Cixl)
   ansiLineToCixlBufferEntries gridWidth (chunks, lineNumber) =
       List.map (\chunk ->
                           chunk.style
                           chunk.text) chunks

   doAnsiShizzle ansiText =

       let model =
                   Ansi.Log.update exampleAnsiText (Ansi.Log.init Cooked )
       in
          Array.map (\ansiLine -> ansiLineToCixlBufferEntries) model.lines

       -- this returns a list of actions like, setbold, movecursor etc
       -- we are only interested in a subset
       -- Ansi.parse ansiText
-}
{-

   toEncoder : Person -> Encode.Encoder
       toEncoder person =
         Encode.sequence
           [ Encode.unsignedInt16 BE person.age
           , Encode.unsignedInt16 BE (Encode.getStringWidth person.name)
           , Encode.string person.name
           ]

       -- encode (toEncoder (Person 33 "Tom")) == <00210003546F6D>
-}


saveAsBytes =
    Bytes.Encode.bytes


type Bit
    = Zero
    | One


not bit =
    if bit == Zero then
        One

    else
        Zero


type alias GlyphBitmap =
    { -- stores the bits in a flat array
      bitmap : Array Bit
    }


type alias FontMap =
    Array GlyphBitmap


type alias ColorDefinition =
    { red : Int, green : Int, blue : Int }


fromCss cssColor =
    ColorDefinition (.red cssColor) (.green cssColor) (.blue cssColor)


type alias ColorPalette =
    Array ColorDefinition


type alias Cixl =
    { glyph : Char, fgColorIndex : Int, bgColorIndex : Int }


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



{- type alias CanvasCixlBuffer =
   { widthInCixls : Int
   , heightInCixls : Int
   , fontMap : FontMap
   , fgPalette : ColorPalette
   , bgPalette : ColorPalette
   , cixlBuffer : Array Cixl
   }
-}
-- TODO:
--  we want to load and save the font-map
--     and the Canvas


bitIsSet : Int -> Int -> Bit
bitIsSet bit number =
    if Bitwise.and bit number == bit then
        One

    else
        Zero


byteToBitmap : Int -> List Bit
byteToBitmap byte =
    -- msb ------ lsb
    [ bitIsSet 128 byte
    , bitIsSet 64 byte
    , bitIsSet 32 byte
    , bitIsSet 16 byte
    , bitIsSet 8 byte
    , bitIsSet 4 byte
    , bitIsSet 2 byte
    , bitIsSet 1 byte
    ]



-- to a 64 element list of Bits
-- this represents 8x8 pixels
--


bytesToGlyphBitmap : List Int -> GlyphBitmap
bytesToGlyphBitmap bytes =
    { bitmap = Array.fromList <| List.concatMap (\byte -> byteToBitmap byte) bytes
    }


fromPixelFontDefinition : List Int -> List GlyphBitmap
fromPixelFontDefinition bytes =
    let
        -- separate the whole list, to lists of 8, since 8 bytes is exactly one glyph (8x8 px)
        step remaining newListOfList =
            case remaining of
                [] ->
                    newListOfList

                _ ->
                    -- per glyph (which is defined in 8 bytes) build a list the bitmap
                    step (List.drop 8 remaining) (newListOfList ++ [ bytesToGlyphBitmap (List.take 8 remaining) ])
    in
    -- a list of 256 (8x8 font bitmap)
    step bytes []


defaultFontMap : FontMap
defaultFontMap =
    Array.fromList <| fromPixelFontDefinition PixelFonts.tinyType


fantasyFontMap =
    Array.fromList <| fromPixelFontDefinition PixelFonts.fantasyType


type alias TileCoordinate =
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



-- drawRawGlyph : Array { a | bitmap : Array Bit } -> ColorPalettes -> Cixl -> Int -> { d | x : Float, y : Float } -> Svg.Svg msg


drawRawGlyph attrs fontMap colorPalettes cixl scaleFactor absScreenPoint extrasPerPixel =
    let
        fgColor =
            Maybe.withDefault { red = 204, green = 204, blue = 204 } (Array.get cixl.fgColorIndex colorPalettes.fg)

        bgColor =
            Maybe.withDefault { red = 0, green = 0, blue = 0 } (Array.get cixl.bgColorIndex colorPalettes.bg)
    in
    case Array.get (Char.toCode cixl.glyph) fontMap of
        Just glyphBitmap ->
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
                                        ([ SvgAttr.fill <| toRgbString fgColor
                                         ]
                                            ++ extrasPerPixel idx
                                        )

                                Zero ->
                                    toSvgRect
                                        (Rectangle.createFromPoint bitAbsCoord
                                            { width = toFloat <| 1 * scaleFactor
                                            , height = toFloat <| 1 * scaleFactor
                                            }
                                        )
                                        ([ SvgAttr.fill <| toRgbString bgColor ] ++ extrasPerPixel idx)
                        )
                        glyphBitmap.bitmap

        Nothing ->
            Svg.g [] []


toVector2 intPoint =
    Vector2.vector2 (toFloat intPoint.x) (toFloat intPoint.y)


indexToXandY rowWidth idx =
    { x = modBy rowWidth idx, y = idx // rowWidth }


xAndYToIndex rowWidth value =
    (value.y * rowWidth) + value.x



-- { x = modBy rowWidth idx, y = idx // rowWidth }
--- GENERAL SVG RENDER FUNCTIONS


toSvgRect forRectangle attributes =
    Svg.rect
        ([ SvgAttr.x (String.fromFloat forRectangle.x)
         , SvgAttr.y (String.fromFloat forRectangle.y)
         , SvgAttr.width (String.fromFloat forRectangle.width)
         , SvgAttr.height (String.fromFloat forRectangle.height)
         ]
            ++ attributes
        )
        []



--- APP SHIZZLE


type alias ColorPalettes =
    { fg : ColorPalette, bg : ColorPalette }


type alias MainModel =
    { fontMap : FontMap
    , fontMapGridScale : Int
    , editorMode : EditorMode
    , canvasModel : CanvasModel
    , glyphToShowInEditor : Char
    , selectedFgIdx : Int
    , selectedBgIdx : Int
    , currentPalettes : ColorPalettes
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


type alias Cursor =
    { position : TileCoordinate
    }


type alias GridSize =
    { width : Int, height : Int }


type alias CanvasCixlBuffer =
    Dict Int Cixl


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
    { fontMap = fantasyFontMap
    , fontMapGridScale = 3
    , editorMode = CanvasMode
    , canvasModel =
        { cursor = { position = { x = 0, y = 0 } }
        , gridSizeInTiles = { width = 40, height = 30 }
        , cixlBuffer = textToCixlBuffer { x = 17, y = 13 } 40 defaultText
        , scaleFactor = 4
        , currentCanvasTool = TypingTool
        }
    , glyphToShowInEditor = Char.fromCode 0
    , selectedFgIdx = 1
    , selectedBgIdx = 0
    , currentPalettes = defaultPalettes
    }


type NavigationAction
    = MoveUp
    | MoveDown
    | MoveLeft
    | MoveRight
    | MoveToStartOfRow
    | MoveToEndOfRow
    | MoveToStartOfNextLine
    | MoveToPosition TileCoordinate


type CanvasMessage
    = None
    | MoveCanvasCursor NavigationAction
    | PaintTile TileCoordinate
    | SelectTileColors TileCoordinate
    | TypeAction Char
    | Backspace -- dunno a better name
    | Delete


type GlyphEditorMessage
    = ToggleBit Int


type ColorPalettesMessage
    = UpdateCurrentSelectedColor ( PaletteType, ColorDefinition )


type EditorModeAction
    = CanvasAction CanvasMessage
    | GlyphEditorAction GlyphEditorMessage
    | ColorPalettesAction ColorPalettesMessage
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
    Debug.log key <|
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

                                    _ ->
                                        CanvasAction None

            _ ->
                Noop


subscriptions : MainModel -> Sub UpdateMsg
subscriptions model =
    {- Sub.none -}
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
            if keyboardEvent.ctrlKey == False && keyboardEvent.altKey == False && keyboardEvent.keyCode /= Tab then
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

        PaletteColorPickerClicked ( paletteType, hexColorString ) ->
            let
                color =
                    --Debug.log hexColorString
                    fromCss (hex hexColorString)
            in
            handleAction (ColorPalettesAction (UpdateCurrentSelectedColor ( paletteType, color ))) model


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
                                    Array.set bitIndex (not (Maybe.withDefault Zero (Array.get bitIndex glyph.bitmap))) glyph.bitmap

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


paintTile : CanvasCixlBuffer -> Int -> TileCoordinate -> Int -> Int -> CanvasCixlBuffer
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
    Css.batch [ fontFamilies [ "VT323", "monospace" ] ]


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
                       /* latin */
                       @font-face {
                         font-family: 'VT323';
                         font-style: normal;
                         font-weight: 400;
                         font-display: swap;
                         src: url(https://fonts.gstatic.com/s/vt323/v17/pxiKyp0ihIEF2isfFJU.woff2) format('woff2');
                         unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
                       }
                       """
            ]
        , div [ css [ displayFlex, defaultTextStyle ] ]
            [ lazy3 renderColorPalettes mainModel.currentPalettes mainModel.selectedFgIdx mainModel.selectedBgIdx
            , renderCanvasActionsPanel mainModel.canvasModel.currentCanvasTool
            , lazy3 renderCanvas mainModel.fontMap mainModel.currentPalettes mainModel.canvasModel
            , div
                [ css [ backgroundColor (hex "#efefef") ]
                ]
                [ -- renderShortcutsGlyphSelector mainModel.fontMap mainModel.currentPalettes mainModel.selectedFgIdx mainModel.selectedBgIdx TODO
                  lazy3 renderFontMap mainModel.fontMap mainModel.fontMapGridScale (Char.toCode mainModel.glyphToShowInEditor)
                , lazy5 renderSelectedGlyphEditor mainModel.fontMap mainModel.currentPalettes mainModel.selectedFgIdx mainModel.selectedBgIdx mainModel.glyphToShowInEditor
                , renderStatusBar mainModel.canvasModel.gridSizeInTiles mainModel.canvasModel.cursor.position (Char.toCode mainModel.glyphToShowInEditor) mainModel.editorMode mainModel.canvasModel.currentCanvasTool
                ]
            ]
        ]


editorModeToString : EditorMode -> String
editorModeToString editorMode =
    case editorMode of
        CanvasMode ->
            "edit mode"

        FontMapSelectorMode ->
            "select font"

        GlyphEditorMode ->
            "glyph edit"


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
        [ css [ fontSize (px 20), marginTop (px -3), paddingTop (px 11), paddingBottom (px 8), backgroundColor (rgb 15 15 15), color (rgb 215 215 215), textAlign center ]
        ]
        [ div []
            [ div [ css [ paddingBottom (px 8) ] ] [ text <| String.fromInt selectedChar ++ " - 0x" ++ String.toUpper (Hex.toString selectedChar) ++ " - " ++ String.fromChar (Char.fromCode selectedChar) ]
            , div []
                [ span [ css [ width (ch 24), display inlineBlock ] ] [ text <| editorModeToString editorMode ++ " | " ++ activeToolToString canvasTool ++ " | " ]
                , span [ css [ width (ch 8), display inlineBlock ] ] [ text <| String.fromInt canvasGridSize.width ++ "x" ++ String.fromInt canvasGridSize.height ++ " | " ]
                , span [ css [ width (ch 5), display inlineBlock ] ] [ text <| String.fromInt cursorPos.y ++ ":" ++ String.fromInt cursorPos.x ]
                ]
            ]
        ]


oneColorPalettes =
    { fg = Array.fromList [ fromCss <| hex "#FFFFFF" ]
    , bg = Array.fromList [ fromCss <| hex "#000000" ]
    }


renderShortcutsGlyphSelector fontMap colorPalettes fgColorIndex bgColorIndex =
    let
        scaleFactor =
            3
    in
    div
        [ css
            [ displayFlex
            , flexWrap wrap
            ]
        ]
        [ div [ css [ width (px <| scaleFactor * glyphSizeInPx), margin (px 2) ] ]
            [ -- key shortcut
              --   glyph
              div [] [ text "F1" ]
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
                    [ drawRawGlyph []
                        fontMap
                        colorPalettes
                        { glyph = '=', fgColorIndex = fgColorIndex, bgColorIndex = bgColorIndex }
                        1
                        Vector2.zeroVector
                        (\_ -> [])
                    ]
                ]
            ]
        ]


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


renderCanvasActionsPanel currentTool =
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
        , hr [ css [ width (px <| (24 * 2) - 2) ] ] []
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
        [ drawRawGlyph [] fantasyFontMap defaultPalettes { glyph = Char.fromCode charCode, fgColorIndex = 15, bgColorIndex = 2 } 1 { x = 0, y = 0 } (\_ -> [])
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
               , span [ css [ display inlineBlock, width (px leftBarWidth), textAlign center, color (rgb 215 215 215), fontSize (px 20) ] ] [ text selectedFgColorHexStr ]
               , label
                    [ for "fgColorPicker"
                    , css
                        [ color (rgb 175 175 175)
                        , width (px leftBarWidth)
                        , margin (px 0)
                        , textAlign center
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
               , span [ css [ display inlineBlock, width (px leftBarWidth), textAlign center, color (rgb 215 215 215), fontSize (px 20) ] ] [ text selectedBgColorHexStr ]
               , label
                    [ for "bgColorPicker"
                    , css
                        [ color (rgb 175 175 175)
                        , width (px leftBarWidth)
                        , margin (px 0)
                        , textAlign center
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

            {- Nothing ->
               hover [ cursor default ]
            -}
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
            -- Svg.Styled.Lazy.lazy5
            renderCanvasCixl cixl fontMapIdx fontMap colorPalettes gridWidthInTiles
                :: acc
        )
        []
        cixlBuffer


renderCanvasCixl cixl fontMapIdx fontMap colorPalettes gridWidthInTiles =
    Svg.Styled.Keyed.node "g" [] [ ( "canvas-" ++ String.fromInt fontMapIdx, drawRawGlyph [] fontMap colorPalettes cixl 1 (tileToScreen (indexToXandY gridWidthInTiles fontMapIdx)) (\_ -> []) ) ]


tileToScreen tileCoord =
    Vector2.scale glyphSizeInPx (toVector2 tileCoord)


fontMapCharCodes =
    List.range 0 255



-- renderFontMap : FontMap -> Int -> Html UpdateMsg


renderFontMap fontMap fontMapGridScale selectedChar =
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
            (renderFontGlyphAsSvg fontMap scaleFactor selectedChar)
            fontMapCharCodes



{- renderKeyedFontGlyphAsSvg fontMap scaleFactor selectedChar charIdx =
   ( "fm-" ++ String.fromInt charIdx, lazy4 renderFontGlyphAsSvg fontMap scaleFactor selectedChar charIdx )
-}


renderFontGlyphAsSvg fontMap scaleFactor selectedChar charIdx =
    Svg.svg
        [ -- The size on the screen
          SvgAttr.width <| String.fromFloat <| glyphSizeInPx * scaleFactor
        , SvgAttr.height <| String.fromFloat <| glyphSizeInPx * scaleFactor
        , SvgAttr.viewBox "0 0 8 8" -- zoom with viewport
        , SvgAttr.css
            [ margin (px 1)
            , if charIdx == selectedChar then
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