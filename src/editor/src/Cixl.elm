module Cixl exposing (..)

import Array exposing (Array)
import Bitwise
import Dict exposing (Dict)


type Bit
    = Zero
    | One


bitNot bit =
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


type alias ColorPalette =
    Array ColorDefinition


type alias ColorPalettes =
    { fg : ColorPalette, bg : ColorPalette }


type alias Cixl =
    { glyph : Char, fgColorIndex : Int, bgColorIndex : Int }


type alias CanvasCixlBuffer =
    Dict Int Cixl


bitIsSet : Int -> Int -> Bit
bitIsSet bit value =
    if Bitwise.and bit value == bit then
        One

    else
        Zero


byteToBits : Int -> List Bit
byteToBits byte =
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


bitToInt bit =
    case bit of
        Zero ->
            0

        One ->
            1


bitsArrayToByte : Array Bit -> Int
bitsArrayToByte arrayOf8Bits =
    bitsIndexedListToByte (Array.toIndexedList arrayOf8Bits)


bitsIndexedListToByte : List ( Int, Bit ) -> Int
bitsIndexedListToByte arrayOf8Bits =
    List.foldl
        (\( idx, bitValue ) total ->
            Bitwise.or total <|
                -- this is the idx'th bit so shift
                Bitwise.shiftLeftBy (7 - idx)
                    -- 0 or 1
                    (bitToInt bitValue)
        )
        0
        arrayOf8Bits


{-| to a 64 element list of Bits
this represents 8x8 pixels
-}
bytesToGlyphBitmap : List Int -> GlyphBitmap
bytesToGlyphBitmap bytes =
    { bitmap = Array.fromList <| List.concatMap (\byte -> byteToBits byte) bytes
    }


{-|

    you can 'loop' through a list in chunks
    calls 'mapChunk' with a part of the given 'list' with a list of size 'chunkSize'

-}
chunkConcat : (List a -> b) -> Int -> List a -> List b
chunkConcat mapChunk chunkSize list =
    let
        -- separate the whole list, to lists of size chunkSize
        step remaining newListOfList =
            case remaining of
                [] ->
                    newListOfList

                _ ->
                    -- per chunk call mapChunk
                    step (List.drop chunkSize remaining) (newListOfList ++ [ mapChunk (List.take chunkSize remaining) ])
    in
    -- a list of 256 (8x8 font bitmap)
    step list []
