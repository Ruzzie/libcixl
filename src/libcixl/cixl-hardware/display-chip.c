//
// Created by dorus on 9-6-2022.
//

#include "display-chip.h"

// Represents the Mapped memory of the display adapter

//! 8x8 pixel bitmap raster thingy
typedef struct CIXL_FontGlyph
{
    uint8_t pixels[8];

} CIXL_FontGlyph;

typedef struct CIXL_FontMap
{
    CIXL_FontGlyph glyphs[256];

} CIXL_FontMap;

typedef struct CIXL_Color
{
    uint8_t r;
    uint8_t g;
    uint8_t b;

} CIXL_Color;


typedef struct CIXL_ColorPalette
{
    CIXL_Color colors[16];

} CIXL_ColorPalette;


typedef struct CIXL_BufferChar
{
    uint8_t char_idx: 8;
    uint8_t fg_color_idx: 4;
    uint8_t bg_color_idx: 4;

} CIXL_BufferChar;


typedef struct CIXL_CharacterBuffer
{
    CIXL_BufferChar chars[80 * 60];
} CIXL_CharacterBuffer;


typedef struct CIXL_DisplayMemoryMap
{
    CIXL_FontMap         font_map;
    CIXL_ColorPalette    fg_color_palette;
    CIXL_ColorPalette    bg_color_palette;
    CIXL_CharacterBuffer character_buffer;
} CIXL_DisplayMemoryMap;


CIXL_DisplayMemoryMap DISPLAY_MEMORY_MAP;

// we need some  api calls to manipulate the display memory
//  ??one could imagine that this is relatively 'slow' like going over a serial sdc line??

void write_byte(const uint16_t addr, const uint8_t data)
{
}

void write(const uint16_t addr, const uint16_t data)
{
}

void write_font_map(const CIXL_FontMap *src)
{
}
//single glyph

CIXL_FontMap read_font_map()
{
}

void write_fg_color_palette()
{}

void write_bg_color_palette()
{}

void write_fg_color_palette_idx(const int palette_idx, const CIXL_Color *color)
{}

void write_bg_color_palette_idx(const int palette_idx, const CIXL_Color *color)
{}

void write_cixl(const int x, const int y, const char char_idx, const uint8_t fg_color_idx, const uint8_t bg_color_idx)
{
}

void swap_colors(const int x, const int y)
{}

void swap_colors_area(const int x, const int y, const int width, const int height)
{}

void set_colors(const int x, const int y, const uint8_t fg_color_idx, const uint8_t bg_color_idx)
{}

void set_colors_area(const int x
                     , const int y
                     , const int width
                     , const int height
                     , const uint8_t fg_color_idx
                     , const uint8_t bg_color_idx)
{}


void
print(const int start_x, const int start_y, const char *str, const uint8_t fg_color_idx, const uint8_t bg_color_idx)
{

}




// and a 'hal' driver / renderer intf

// programmer-api
//    |
// hardware-os-api
//    |
//  driver