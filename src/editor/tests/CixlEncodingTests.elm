module CixlEncodingTests exposing (..)

import Array exposing (Array)
import Cbor.Decode
import Cbor.Encode
import Cixl exposing (..)
import Expect exposing (FloatingPointTolerance(..))
import Main exposing (..)
import Serialize as S
import Test exposing (Test, describe, test)



-- A GlyphBitmap has 8 bytes, one byte per 'row' of pixel information
--  this is stored in the 'bitmap' which is an array of Bits,
---- one glyph of pixel information has 64 bits ( 8bytes * 8 bits)


glyphBitmapCborDecoder : Cbor.Decode.Decoder GlyphBitmap
glyphBitmapCborDecoder =
    Cbor.Decode.map (\allBits -> { bitmap = Array.fromList allBits })
        (Cbor.Decode.map (\listOfIntsThatRepresentBytes -> List.concatMap byteToBits listOfIntsThatRepresentBytes)
            (Cbor.Decode.list Cbor.Decode.int)
        )


glyphBitmapCborEncoder : GlyphBitmap -> Cbor.Encode.Encoder
glyphBitmapCborEncoder glyphBitmap =
    Cbor.Encode.list Cbor.Encode.int (chunkConcat (\chunk -> bitsArrayToByte (Array.fromList chunk)) 8 (Array.toList glyphBitmap.bitmap))


emptyGlyph : GlyphBitmap
emptyGlyph =
    { bitmap = Array.fromList [] }


suite : Test
suite =
    describe "GlyphBitmap encoding"
        [ -- bitsArrayToByte
          test "bitsArrayToByte, encode one byte : 1" <|
            \_ ->
                let
                    bits =
                        Array.fromList [ Zero, Zero, Zero, Zero, Zero, Zero, Zero, One ]
                in
                bitsArrayToByte bits |> Expect.equal 1
        , test "bitsArrayToByte, encode one byte : 128" <|
            \_ ->
                let
                    bits =
                        Array.fromList [ One, Zero, Zero, Zero, Zero, Zero, Zero, Zero ]
                in
                bitsArrayToByte bits |> Expect.equal 128
        , test "bitsArrayToByte, encode one byte : 33" <|
            \_ ->
                let
                    bits =
                        Array.fromList [ Zero, Zero, One, Zero, Zero, Zero, Zero, One ]
                in
                bitsArrayToByte bits |> Expect.equal 33
        , test "byteToBits decode 1 byte : 1" <|
            \_ ->
                let
                    bits =
                        [ Zero, Zero, Zero, Zero, Zero, Zero, Zero, One ]
                in
                byteToBits 1 |> Expect.equal bits
        , test "byteToBits decode 1 byte : 33" <|
            \_ ->
                let
                    bits =
                        [ Zero, Zero, One, Zero, Zero, Zero, Zero, One ]
                in
                byteToBits 33 |> Expect.equal bits
        , test "decode encode GlyphBitmap as inefficient int list" <|
            \_ ->
                let
                    firstGlyph =
                        Maybe.withDefault emptyGlyph <| Array.get 0 defaultFontMap

                    encodedGlyphBitmap =
                        Cbor.Encode.encode (glyphBitmapCborEncoder firstGlyph)

                    decodedGlyphBitmap =
                        Cbor.Decode.decode glyphBitmapCborDecoder encodedGlyphBitmap
                in
                decodedGlyphBitmap |> Expect.equal (Just firstGlyph)
        , test "test Codec GlyphBitmap" <|
            \_ ->
                let
                    firstGlyph =
                        Maybe.withDefault emptyGlyph <| Array.get 0 defaultFontMap

                    encodedGlyphBitmap =
                        S.encodeToString glyphBitmapCodec firstGlyph

                    decodedGlyphBitmap =
                        S.decodeFromString glyphBitmapCodec encodedGlyphBitmap
                in
                case decodedGlyphBitmap of
                    Ok decoded ->
                        decoded
                            |> Expect.equal firstGlyph

                    Err err ->
                        Expect.fail (Debug.toString err)
        , test "test GlyphBitmap Codec re-encode" <|
            \_ ->
                let
                    firstGlyph =
                        Maybe.withDefault emptyGlyph <| Array.get 0 defaultFontMap

                    encodedGlyphBitmap =
                        S.encodeToString glyphBitmapCodec firstGlyph

                    decodedGlyphBitmap =
                        S.decodeFromString glyphBitmapCodec encodedGlyphBitmap
                in
                case decodedGlyphBitmap of
                    Ok decoded ->
                        S.encodeToString glyphBitmapCodec decoded
                            |> Expect.equal encodedGlyphBitmap

                    Err err ->
                        Expect.fail (Debug.toString err)
        , test "test FontMap Codec re-encode" <|
            \_ ->
                let
                    encodedFontMap =
                        S.encodeToString fontMapCodec defaultFontMap

                    decodedFontMap =
                        S.decodeFromString fontMapCodec encodedFontMap
                in
                case decodedFontMap of
                    Ok decoded ->
                        S.encodeToString fontMapCodec decoded
                            |> Expect.equal encodedFontMap

                    Err err ->
                        Expect.fail (Debug.toString err)
        ]



-- glyphBitmapCodec
{-


   glyphBitmapBinaryEncoder : GlyphBitmap -> Cbor.Encode.Encoder
   glyphBitmapBinaryEncoder glyphBitmap =
        Cbor.Encode.in


   fontMapBinaryEncoder : FontMap -> Cbor.Encode.Encoder
   fontMapBinaryEncoder fontmap =
        Cbor.Encode.list glyphBitmapBinaryEncoder  ( Array.toList fontmap)


   suite : Test
   suite =
       describe "FontMap to and from Bytes encoding test"
           [ test "decode returns Just (no error)" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       decoded =
                           Bytes.Decode.decode fontMapBinaryDecoder encodedDefaultFontMap
                   in
                   Expect.notEqual Nothing decoded
           , test "Encode has length of 8 * 256 bytes" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)
                   in
                   Bytes.width encodedDefaultFontMap
                       |> Expect.equal (8 * 256)
           , test "Encode first byte correct" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       firstByte =
                           Bytes.Decode.decode Bytes.Decode.unsignedInt8 encodedDefaultFontMap
                   in
                   Expect.equal firstByte (Just 1)
           , test "int to bits (1)" <|
               \_ ->
                   bytesToGlyphBitmap [ 1 ]
                       |> Expect.equal { bitmap = Array.fromList [ Zero, Zero, Zero, Zero, Zero, Zero, Zero, One ] }
           , test "int to bits (4)" <|
               \_ ->
                   bytesToGlyphBitmap [ 4 ]
                       |> Expect.equal { bitmap = Array.fromList [ Zero, Zero, Zero, Zero, Zero, One, Zero, Zero ] }
           , test "Decode return correct sized array" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       decoded =
                           Bytes.Decode.decode fontMapBinaryDecoder encodedDefaultFontMap
                   in
                   case decoded of
                       Just decodedFontMap ->
                           Array.length decodedFontMap
                               |> Expect.equal 256

                       Nothing ->
                           Expect.fail "decoding failed"
           , test "Decode first byte correct" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       decoded =
                           Bytes.Decode.decode fontMapBinaryDecoder encodedDefaultFontMap
                   in
                   case decoded of
                       Just decodedFontMap ->
                           Array.get 0 Main.defaultFontMap
                               |> Expect.equal (Array.get 0 decodedFontMap)

                       Nothing ->
                           Expect.fail "decoding failed"
           , test "Encode last byte correct" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       lastByte =
                           Bytes.Decode.decode (Bytes.Decode.map2 (\a b -> b) (Bytes.Decode.bytes ((8 * 256) - 1)) Bytes.Decode.unsignedInt8) encodedDefaultFontMap
                   in
                   lastByte
                       |> Expect.equal (Just 1)
           , test "decode / encode are same length" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       decoded =
                           Bytes.Decode.decode fontMapBinaryDecoder encodedDefaultFontMap
                   in
                   Maybe.withDefault -1 (Maybe.map (\x -> Array.length x) decoded)
                       |> Expect.equal (List.length (Array.toList Main.defaultFontMap))
           , test "decode / encode returns to the same first element" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       decoded =
                           Bytes.Decode.decode fontMapBinaryDecoder encodedDefaultFontMap
                   in
                   List.head (Maybe.withDefault [] (Maybe.map (\x -> Array.toList x) decoded))
                       |> Expect.equal (List.head (Array.toList Main.defaultFontMap))
           , test "decode / encode returns to the same last element" <|
               \_ ->
                   let
                       encodedDefaultFontMap =
                           Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                       decoded =
                           Bytes.Decode.decode fontMapBinaryDecoder encodedDefaultFontMap
                   in
                   Expect.equal (List.head <| List.drop 255 (Maybe.withDefault [] (Maybe.map (\x -> Array.toList x) decoded))) (List.head <| List.drop 255 (Array.toList Main.defaultFontMap))

           {- , test "decode / encode returns to the same base64 encoded string" <|
              \_ ->
                  let
                      encodedDefaultFontMap =
                          Bytes.Encode.encode (fontMapBinaryEncoder Main.defaultFontMap)

                      decodedMaybe =
                          Bytes.Decode.decode fontMapBinaryDecoder encodedDefaultFontMap

                      reEncodedAsBase64String =
                          Maybe.withDefault "" <|
                              Maybe.map (\decoded -> base64Encode (Bytes.Encode.encode (fontMapBinaryEncoder decoded)))
                                  decodedMaybe

                      encodedAsBase64String =
                          base64Encode encodedDefaultFontMap
                  in
                  Expect.equal encodedAsBase64String reEncodedAsBase64String
           -}
           ]
-}
