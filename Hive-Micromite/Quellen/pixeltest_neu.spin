CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  tiles    = vga#xtiles * vga#ytiles
  tiles32  = tiles * 32

OBJ
  vga : "VGA_Pixel"'"vga_512x384_bitmap"

VAR
  long  sync, pixels[tiles32]
  word  colors[tiles]

PUB start | h, i, j, k, x, y
  'start vga
  vga.start(8, @colors, @pixels, @sync)
  'implant pointers and launch assembly program into COG
  asm_colors := @colors
  asm_pixels := @pixels
  asm_sync := @sync
  cognew(@asm_entry, 0)

DAT  '
'
' Assembly program
'
              org
asm_entry     mov counter1, #192                        '192 words to write
 :loop        wrword palette,asm_colors                 'write to hub ram.
              add asm_colors , #2                       'move forward 2 bytes
              djnz counter1, #:loop


scroller      mov fontpntr, text wz                     'init font pointer
              add scroller, #1                          'self modifying code
              if_z movs scroller, #text                 'reset text pointer
              if_z mov fontpntr, #32                    'use space
              mov mask, #%01
              shr fontpntr, #1 wc                       'no odd numbers please, but let me know if it was.
              if_c mov mask, #%10
              shl fontpntr, #7                          'multiply by 64 plus counteract the SHR above
              add fontpntr,fontrom                      'adds $8000 +127

:waitforsync  rdlong sync_clear, asm_sync wz            'read long from hub ram and with a zero flag check
              if_z jmp #:waitforsync                    'if zero, test again.
              mov sync_clear, #0                        'reset it,
              wrlong sync_clear,asm_sync                'write long to hub ram
              mov asm_pixpntr, asm_pixels               'buffer the asm_pixel pointer
              add asm_pixpntr, block                    'start in a lower right corner
              mov counter1, #256
              shl counter1, #1                          'make it 512

:loop         rdlong pix_data, asm_pixpntr
              test counter1, #%1111 wz                  'only happens every other 16 times
              if_z  rdlong pix_data2,fontpntr           'read font ROM in hub
              if_z  sub fontpntr,#4                     'move up one line for next time
              if_z  test pix_data2,mask wc              'set c flag if a 1, as 1 it's an odd number of bits.
              rcr pix_data, #1 wc                       'shift right with carry flag, use #2 for double speed/wide font
              wrlong pix_data, asm_pixpntr              'write to the bitmap in hub
              sub asm_pixpntr, #4                       'move backwards 4 bytes
              djnz counter1, #:loop

              add fontpntr, #128                        'counteract all the the sub4 that was done 32 times.
              shl mask,#2  wz                           'shift left, z flag if you shifted youself out to zero
              if_nz jmp #:waitforsync                   'if it was not zero, just wait for sync and use same font.
              jmp #scroller

asm_colors    long    0                               'pixel base (set at runtime)                            '
asm_pixels    long    0                               'pixel base (set at runtime)
asm_sync      long    0                               'sync (set at runtime)
palette       long    %100000 <<10 + %000001 <<2      'RrGgBbxx + RrGgBbxx (forground and background colors)
block         long    64*32*3-4                       'start at 3 blocks down, line31 right side
fontrom       long    $8000+127                       'ROM location$8000 plus start 31 lines down
text          long    "          I have been impressed with the urgency of doing. Knowing is not enough; we must apply."
              long    " Being willing is not enough; we must do. ( Leonardo da Vinci )"
              long    "       We have to do the best we can. This is our sacred human responsibility. (Albert Einstein)",0
asm_pixpntr   res     1                               'buffer for asm_pixels pointer
pix_data      res     1                               'buffer for vga bitmap
pix_data2     res     1                               'buffer for font bits
mask          res     1                               'the rolling mask
sync_clear    res     1
counter1      res     1
fontpntr      res     1


