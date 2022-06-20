module Exports exposing (..)

import Array exposing (Array)
import Cixl exposing (..)
import Hex


toHexString : Int -> String
toHexString byte =
    "0x"
        ++ String.padLeft 2 '0' (String.toUpper (Hex.toString byte))


fontMapToCommaSeparatedHexString lineIndent fontMap =
    let
        glyph : Array Bit -> List String
        glyph glyphBitmap =
            chunkConcat
                (\byteChunk ->
                    String.padRight 4
                        ' '
                        (toHexString <| bitsArrayToByte (Array.fromList byteChunk))
                        ++ ", "
                )
                8
                (Array.toList glyphBitmap)
    in
    String.concat
        (List.concatMap (\( idx, g ) -> [ String.repeat lineIndent " " ] ++ glyph g.bitmap ++ [ " // char ", String.fromInt idx, "\n" ]) (Array.toIndexedList fontMap))


colorPaletteToCommaSeparatedHexString : Int -> ColorPalette -> String
colorPaletteToCommaSeparatedHexString lineIndent colorPalette =
    let
        colorToStr : ColorDefinition -> List String
        colorToStr color =
            List.map
                (\colorByte ->
                    String.padRight 4
                        ' '
                        (toHexString colorByte)
                        ++ ", "
                )
                [ color.red, color.green, color.blue ]
    in
    String.concat
        (List.concatMap (\( idx, color ) -> [ String.repeat lineIndent " " ] ++ colorToStr color ++ [ " //  color idx ", String.fromInt idx, "\n" ]) (Array.toIndexedList colorPalette))


colorPaletteToArrayAssignmentHexString : String -> Int -> ColorPalette -> String
colorPaletteToArrayAssignmentHexString arrayName lineIndent colorPalette =
    let
        colorToStr : Int -> ColorDefinition -> List String
        colorToStr colorMapIdx color =
            List.indexedMap
                (\idx colorByte ->
                    String.repeat lineIndent
                        " "
                        ++ (arrayName ++ "[" ++ String.fromInt ((colorMapIdx * 3) + idx) ++ "] = " ++ toHexString colorByte ++ ";\n")
                )
                [ color.red, color.green, color.blue ]
    in
    String.concat
        (List.concatMap
            (\( idx, color ) ->
                ([ String.repeat lineIndent " " ] ++ [ " //  color palette idx ", String.fromInt idx, "\n" ])
                    ++ colorToStr idx color
            )
            (Array.toIndexedList colorPalette)
        )


cixlExportHeader =
    """
// ·————·
// |CIXL|
// ·————·
//"""


colorPalettesToC : ColorPalettes -> String
colorPalettesToC colorPalettes =
    cixlExportHeader
        ++ """
// COLOR PALETTES
//
// a color is 3 bytes (red, green, blue), a colorPalette is 16 colors
// so the size is 16 * 3 (byte r, byte g, byte b)
    
unsigned char fg_color_palette[48] =
{

"""
        ++ colorPaletteToCommaSeparatedHexString 4 colorPalettes.fg
        ++ """
};
"""
        ++ """        
unsigned char bg_color_palette[48] =
{

"""
        ++ colorPaletteToCommaSeparatedHexString 4 colorPalettes.bg
        ++ """
};
"""


fontMapToC : FontMap -> String
fontMapToC fontMap =
    cixlExportHeader
        ++ """
// FONT
                
unsigned char font[2048] =
{

"""
        ++ fontMapToCommaSeparatedHexString 4 fontMap
        ++ "};"


exportToC fontMap colorPalettes =
    colorPalettesToC colorPalettes
        ++ "\n"
        ++ fontMapToC fontMap


exportToCSharpUnsafe fontMap colorPalettes =
    cixlExportHeader
        ++ """
    namespace Cixl;
    
    """
        ++ """
public struct ColorPalettes
{
    // 16 fg colors, 16 bg colors, a color is r,g,b
    private unsafe fixed byte _fgColorPalette[48];
    private unsafe fixed byte _bgColorPalette[48];

   public ColorPalettes()
   {
       unsafe
       {
         
    """
        ++ """
         // fg colors

"""
        ++ colorPaletteToArrayAssignmentHexString "_fgColorPalette" 12 colorPalettes.fg
        ++ """
         // end of fg
         """
        ++ """
         
         // bg colors

"""
        ++ colorPaletteToArrayAssignmentHexString "_bgColorPalette" 12 colorPalettes.bg
        ++ """
        
         // end of bg colors
         """
        ++ """
       }
   }
}

    """
        ++ fontMapToCSharp fontMap


exportToCSharp fontMap colorPalettes =
    cixlExportHeader
        ++ """
namespace Cixl;

"""
        ++ """
public static class ColorPalettes
{
     
"""
        ++ """
    public static readonly byte[] fgColorPalette =
    {
"""
        ++ colorPaletteToCommaSeparatedHexString 8 colorPalettes.fg
        ++ """
     };
     """
        ++ """
     public static readonly byte[] bgColorPalette =
     {
"""
        ++ colorPaletteToCommaSeparatedHexString 8 colorPalettes.bg
        ++ """
     };
     """
        ++ """
}

"""
        ++ fontMapToCSharp fontMap


fontMapToCSharp : FontMap -> String
fontMapToCSharp fontMap =
    """
        
public static class Fonts
{
    public static readonly byte[] font =
    {

"""
        ++ fontMapToCommaSeparatedHexString 8 fontMap
        ++ """
    };
}    
    """
