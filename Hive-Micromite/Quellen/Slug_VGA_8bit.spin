''********************************************
''*  VGA 128x96 64-Color Bitmap Driver v1.0  *
''*  Author: Andy Schenk                     *
''*  See end of file for terms of use.       *
''********************************************
''*  based on Chip Gracey's 512x384 Bitmap driver
''
'' This object generates a 128x96 pixel bitmap, signaled as 1024x768 VGA.
'' Each pixel is one byte, so the entire bitmap requires 12 kbytes,
'' Pixel memory is arranged left-to-right then top-to-bottom.
''
'' A sync indicator signals each time the screen is drawn (you may ignore).
''
'' You must provide buffers for the pixels, and sync. Once started,
'' all interfacing is done via memory. To this object, all buffers are read-
'' only, with the exception of the sync indicator which gets written with a
'' non-0 value. You may freely write all buffers to affect screen appearance.
''

CON

' 128x96 settings - signals as 1024 x 768 @ 60Hz

  hp = 128      'horizontal pixels
  vp = 96       'vertical pixels
  hf = 24       'horizontal front porch pixels
  hs = 136      'horizontal sync pixels
  hb = 160      'horizontal back porch pixels
  vf = 3        'vertical front porch lines
  vs = 6        'vertical sync lines
  vb = 29       'vertical back porch lines
  hn = 1        'horizontal normal sync state (0|1)
  vn = 1        'vertical normal sync state (0|1)
  pr = 65       'pixel rate in MHz at 80MHz system clock (5MHz granularity)

' Tiles

  xtiles = hp / 4

' H/V inactive states
  
  hv_inactive = (hn << 1 + vn) * $01010101


VAR long cog

PUB start(ColorMode, PixelPtr, SyncPtr) : okay

'' Start VGA driver - starts a COG
'' returns false if no COG available
''
''     BasePin = VGA starting pin (0, 8, 16, 24, etc.)
''
''    PixelPtr = Pointer to 12288 bytess containing colors that make up the
''               192 x 96 pixel bitmap. Only the upper 6 bits of a byte are
''               used to set one of 64 colors.
''               color byte examples: %%0020 = blue, %%3300 = gold 
''
''     SyncPtr = Pointer to long which gets written with non-0 upon each screen
''               refresh. May be used to time writes/scrolls, so that chopiness
''               can be avoided. You must clear it each time if you want to see
''               it re-trigger.

  'if driver is already running, stop it
  stop

  'implant pin settings and pointers, then launch COG
  'reg_vcfg := $300000FF + (BasePin & %111000) << 6
  'reg_dira := $FF << (BasePin & %011000)

  'if ColorMode == 0
     long[@reg_outa] := %0000_0000_0000_0000_0000_0011_0000_0000
     long[@reg_dira] := %0000_0000_0000_0000_1111_1111_0000_0000
  'else
  '   long[@sync_vcfg] := %0_01_1_0_0_000_00000100000_011_0_00000011
  
  pixel_base := PixelPtr
  if (cog := cognew(@init, SyncPtr) + 1)
    return true


PUB stop | i

'' Stop VGA driver - frees a COG

  if cog
    cogstop(cog~ - 1)


DAT

'***********************************************
'* Assembly language VGA 2-color bitmap driver *
'***********************************************

                        org                             'set origin to $000 for start of program

' Initialization code - init I/O
                                                                                              
init                    mov     dira,reg_dira           'set pin directions                   
                        'mov     dirb,reg_dirb                                                 

                        movi    ctra,#%00001_110        'enable PLL in ctra (VCO runs at 2x)
                        movi    frqa,#(pr / 5) << 2     'set pixel rate                                      

                        mov     vcfg,vid_vcfg           'set video configuration

' Main loop, display field and do invisible sync lines
                          
field                   mov     pixel_ptr,pixel_base    'reset pixel pointer
                        mov     y,#vp                   'set y lines
:yline                  mov     yx,#8                   'set y expansion                          
:yexpand                mov     x,#xtiles               'set x tiles
                        mov     vscl,vscl_pixel         'set pixel vscl

                        'mov     outa, hv                'take over sync lines
                        'andn    vcfg, #%11              'disconnect from video h/w      (##)

                        mov     vcfg, vid_vcfg
                        or      outa, reg_outa

:xtile

                        rdlong  color,pixel_ptr         'get color word
                        waitvid color,#%%3210           'pass colors and pixels to video
                        add     pixel_ptr,#4            'point to next pixel long
                        djnz    x,#:xtile               'another x tile?

                        sub     pixel_ptr,#xtiles * 4   'repoint to first pixels in same line

                        mov     x,#1                    'do horizontal sync
                        call    #hsync

                        djnz    yx,#:yexpand            'y expand?
                        
                        add     pixel_ptr,#xtiles * 4   'point to first pixels in next line
                        djnz    y,#:yline               'another y line?

                        wrlong   colormask,par          'visible done, write non-0 to sync

                        mov  vcfg,sync_vcfg
                        andn outa , reg_outa
                        mov     x,#vf                   'do vertical front porch lines
                        call    #blank
                        mov     x,#vs                   'do vertical sync lines
                        call    #vsync
                        mov     x,#vb                   'do vertical back porch lines
                        call    #vsync

                        jmp     #field                  'field done, loop
                        

' Subroutine - do blank lines

vsync
                        xor     hvsync,#$101            'flip vertical sync bits
blank                   mov     vscl,hvis               'do blank pixels
                        waitvid hvsync,#0
'hsync
                        mov     vscl,#hf           'do horizontal front porch pixels
                        waitvid hvsync,#0
                        mov     vscl,#hs                'do horizontal sync pixels
                        waitvid hvsync,#1
                        mov     vscl,#hb                'do horizontal back porch pixels
                        waitvid hvsync,#0
                        djnz    x,#blank                'another line?
'hsync_ret
blank_ret
vsync_ret               ret


hsync                   mov     vscl,#hf                'do horizontal front porch pixels
              

                        waitvid hvsync,#0
                        'or      vcfg, #%11              'drive sync lines                       (##)
                        'mov     outa, #0                'stop interfering

                        mov  vcfg,sync_vcfg
                        andn outa , reg_outa
                        mov     vscl,#hs                'do horizontal sync pixels
                        waitvid hvsync,#1
                        mov     vscl,#hb                'do horizontal back porch pixels
                        waitvid hvsync,#0
                        djnz    x,#blank                'another line?
hsync_ret
                        ret


' Data
reg_dira                long    %0000_0011_0000_0000_1111_1111_0000_0000
reg_outa                long    %0000_0011_0000_0000_0000_0000_0000_0000

sync_vcfg               long    %0_01_1_0_0_000_00000100000_001_0_00000011 '%0_01_1_0_0_000_00000100000_001_0_00000011 ' P8,P9 Vsync, Hsync
vid_vcfg                long    %0_01_1_0_0_000_00000100000_001_0_11111111 ' P16-P23 RRRGGGBB data

'reg_dira                long    0                       'set at runtime
'reg_dirb                long    0                       'set at runtime
'reg_vcfg                long    0                       'set at runtime

pixel_base              long    0                       'set at runtime

vscl_pixel              long    8 << 12 + 32            '8 clocks per pixel and 4 pixels per set
colormask               long    $FCFCFCFC               'mask to isolate R,G,B bits from H,V
hvis                    long    hp*8                    'visible pixels per scan line
hv                      long    hv_inactive             '-H,-V states
hvsync                  long    hv_inactive ^ $200      '+/-H,-V states


' Uninitialized data

color_ptr               res     1
pixel_ptr               res     1
color                   res     1
pixel                   res     1
x                       res     1
y                       res     1
yl                      res     1
yx                      res     1

{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
