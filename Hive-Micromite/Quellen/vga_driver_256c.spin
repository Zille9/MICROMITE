''
'' VGA scanline driver 256x256 (single cog) - video driver and pixel generator
''
''        Author: Marko Lukat
'' Last modified: 2012/09/23
''       Version: 0.8
''
'' - timing signalled as XGA 1024x768
'' - vertical blank start sets frame indicator (FI) to 0
'' - once the Nth scanline has been fetched the FI is set to N+1       
''
'' 20120922: make scanline buffer configurable
'' 20120923: match old-style line indicator
'' 20130220: adapted to 256 scanlines
''           changed line indicator reset timing (Marco Maccaferri)
''
'' 20130402: Karl Albrecht, Added Color Mode support 0=64 colors, 1=256 colors
''           Note you need the VGAPlus256 board from PropellerPowered.com to use 256 color mode

CON

  zero    = $1F0                                ' par (dst only)
  vpin    = $0FF                                ' pin group mask
  vgrp    = 1                                   ' pin group
  hv_idle = $01010101 * %11 {%hv}               ' h/v sync inactive

PUB Start(sbuf, fi, ColorMode, GraphicsMode)
  
  
  longfill(sbuf, 0, 64)
  
  blnk := fi                                    ' frame indicator
  base := sbuf                                  ' scanline buffer
  vres := 256
  
  'if GraphicsMode == 2
  '  vres := 192


  if ColorMode == 1
     long[@sync_vcfg] := %0_01_1_0_0_000_00000100000_011_0_00000011
     long[@reg_outa]  := %0000_0011_0000_0000_0000_0000_0000_0000
     long[@reg_dira]  := %0000_0011_1111_1111_0000_0000_0000_0000


  cognew(@driver, 0)
  waitcnt(clkfreq + cnt)                        ' wait for driver to settle

PUB wait_vbl

  repeat
  while long[blnk] == vres                      ' line vres has been fetched (zero based)
  repeat
  while long[blnk] <> vres                      ' vertical starts (vres/0 transition)

DAT             org     0

driver          neg     href, cnt               ' hub window reference (-4)

' Upset video h/w and relatives.

                movi    ctra, #%0_00001_111     ' PLL, VCO/1
                movi    frqa, #%0001_00000      ' 5MHz * 16 / 1 = 80MHz

                mov     vscl, #64               ' 1/64

                'movd    vcfg, #vgrp             ' pin group
                'movs    vcfg, #vpin             ' pins
                'movi    vcfg, #%0_01_1_00_000   ' VGA, 4 colour mode
                mov     vcfg, vid_vcfg

                rdlong  cnt, #0
                shr     cnt, #10                ' ~1ms
                add     cnt, cnt
                waitcnt cnt, #0                 ' PLL needs to settle

' The first issued waitvid is a bit of a gamble if we don't know where the WHOP
' is located. We could do some fancy math or simply issue a dummy waitvid.

                waitvid zero, #0                ' dummy (first one is unpredictable)
                waitvid zero, #0                ' point of reference

                add     href, cnt               ' get current sync slot
                sub     href, #11
                and     href, #%1111

                sub     vscl, href              ' |
                waitvid zero, #0                ' stretch frame
                add     vscl, href              ' |
                waitvid zero, #0                ' restore frame

                'mov     dira,reg_dira
                mov     dira, mask

' Setup complete, enter display loop.

vsync
                mov  vcfg, sync_vcfg
                andn outa, reg_outa

                mov     ecnt, #3
                call    #blank                  ' front porch
                djnz    ecnt, #$-1

                xor     sync, #$0101            ' active

                mov     ecnt, #6
                call    #blank                  ' vertical sync
                djnz    ecnt, #$-1

                xor     sync, #$0101            ' inactive

                mov     ecnt, #10
                call    #blank                  ' back porch
                djnz    ecnt, #$-1

                mov     lcnt, #0                ' |
                wrlong  lcnt, blnk              ' reset line counter (once)

                mov     ecnt, #19 -1
                call    #blank                  ' back porch
                djnz    ecnt, #$-1

                test    $, #1 wc                ' last blank line done manually (%%)
                call    #blank                  ' to start pixel loading
                
' Vertical sync chain done, do visible area.

                mov     scnt, vres

:loop           'mov     outa, idle              ' take over sync lines
                'andn    vcfg, #%11              ' disconnect from video h/w     (##)

                jmpret  hsync_ret, #emit_0

                'mov     outa, idle              ' take over sync lines
                'andn    vcfg, #%11              ' disconnect from video h/w     (##)

                jmpret  hsync_ret, #emit_12

                'mov     outa, idle              ' take over sync lines
                'andn    vcfg, #%11              ' disconnect from video h/w     (##)
                
                cmp     vres, #256 wz           ' check vertical resolution
        if_e    jmp     #$+4

                jmpret  hsync_ret, #emit_12

                mov     vcfg, vid_vcfg
                or      outa, reg_outa

                'mov     outa, idle              ' take over sync lines
                'andn    vcfg, #%11              ' disconnect from video h/w     (##)

' Note: The worst case timing between the last waitvid triggered by emit_3 and the
'       first for vertical blank is 44 cycles (which has to cover one more hubop).

                jmpret  hsync_ret, #emit_3
                
                djnz    scnt, #:loop

                jmp     #vsync


blank           mov     vscl, line              ' 256/1280
                waitvid sync, #%%00000

hsync           mov     vscl, #30               ' 256/30
                waitvid sync, #%%0              ' latch front porch

                mov  vcfg, sync_vcfg
                andn outa, reg_outa

                'or      vcfg, #%11              ' drive sync lines              (##)
                'mov     outa, #0                ' stop interfering

                mov     vscl, slow              ' 170/370
                waitvid sync, #%%1              ' latch sync and back porch

                cmp     lcnt, #0 wz             ' only non-null numbers
        if_nz   wrlong  lcnt, blnk              ' report current line
                
                add     base, #4                ' get all 4n+1 longs a bit earlier
        if_c    rdlong  pal+$01, base
                add     base, #16
        if_c    rdlong  pal+$05, base
                add     base, #16
        if_c    rdlong  pal+$09, base
                add     base, #16
        if_c    rdlong  pal+$0D, base
                add     base, #16
        if_c    rdlong  pal+$11, base
                add     base, #16
        if_c    rdlong  pal+$15, base
                add     base, #16
        if_c    rdlong  pal+$19, base
                add     base, #16
        if_c    rdlong  pal+$1D, base

                nop                             ' make sure the minimal length covers sync
                add     base, #16
        if_c    rdlong  pal+$21, base
                nop                             ' *
                add     base, #16
        if_c    rdlong  pal+$25, base
                nop                             ' *
                add     base, #16
        if_c    rdlong  pal+$29, base
                nop                             ' *
                add     base, #16
        if_c    rdlong  pal+$2D, base
                nop                             ' *
                add     base, #16
        if_c    rdlong  pal+$31, base
                nop                             ' *
                add     base, #16
        if_c    rdlong  pal+$35, base
                nop                             ' *
                add     base, #16
        if_c    rdlong  pal+$39, base
                nop                             ' * (32)
                add     base, #16
        if_c    rdlong  pal+$3D, base

                sub     base, #$F4 wc           ' restore                       (%%)
hsync_ret
blank_ret       ret

'           PLL = 80MHz, vscl = 5/20 (WHOP every 20 clocks, 5 clocks per pixel)
'                            
'                    WHOP 0              WHOP 1              WHOP 2              WHOP 3
'                       |                   |                   |                   |
'    00000000000000000000111111111111111111112222222222222222222233333333333333333333
'    |               |               |               |               |
'    hub window 0    hub window 1    hub window 2    hub window 3    hub window 4
'    |       |   |          |                        |       |   |
'    rdlong  pal+$00, addr  |                        |       |   |
'            add     addr, #8                        |       |   |
'                waitvid pal+$00, #%%3210            |       |   |
'                           waitvid pal+$01, #%%3210 |       |   |
'                                                    |       |   |
'    Here we have 5 hub windows for processing       rdlong  pal+$02, addr
'    16 pixels (4 longs). We lose two of them to             cmp     pal+$02, #%%3210
'    the waitvids. The remaining 8 pixels are                    add     addr, #4

emit_0
                mov     vcfg, vid_vcfg
                or      outa, reg_outa

                mov     addr, base              '  -8
                mov     vscl, hvis              '  -4   pixel timing

                rdlong  pal+$00, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$00, #%%3210
                waitvid pal+$01, #%%3210

                rdlong  pal+$02, addr           '  +0 =
                cmp     pal+$02, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$03, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$03, #%%3210        '  -4   WHOP    0..15


                rdlong  pal+$04, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$04, #%%3210
                waitvid pal+$05, #%%3210

                rdlong  pal+$06, addr           '  +0 =
                cmp     pal+$06, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$07, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$07, #%%3210        '  -4   WHOP    16..31


                rdlong  pal+$08, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$08, #%%3210
                waitvid pal+$09, #%%3210

                rdlong  pal+$0A, addr           '  +0 =
                cmp     pal+$0A, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$0B, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$0B, #%%3210        '  -4   WHOP    32..47


                rdlong  pal+$0C, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$0C, #%%3210
                waitvid pal+$0D, #%%3210

                rdlong  pal+$0E, addr           '  +0 =
                cmp     pal+$0E, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$0F, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$0F, #%%3210        '  -4   WHOP    48..63


                rdlong  pal+$10, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$10, #%%3210
                waitvid pal+$11, #%%3210

                rdlong  pal+$12, addr           '  +0 =
                cmp     pal+$12, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$13, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$13, #%%3210        '  -4   WHOP    64..79


                rdlong  pal+$14, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$14, #%%3210
                waitvid pal+$15, #%%3210

                rdlong  pal+$16, addr           '  +0 =
                cmp     pal+$16, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$17, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$17, #%%3210        '  -4   WHOP    80..95


                rdlong  pal+$18, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$18, #%%3210
                waitvid pal+$19, #%%3210

                rdlong  pal+$1A, addr           '  +0 =
                cmp     pal+$1A, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$1B, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$1B, #%%3210        '  -4   WHOP    96..111


                rdlong  pal+$1C, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$1C, #%%3210
                waitvid pal+$1D, #%%3210

                rdlong  pal+$1E, addr           '  +0 =
                cmp     pal+$1E, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$1F, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$1F, #%%3210        '  -4   WHOP    112..127


                rdlong  pal+$20, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$20, #%%3210
                waitvid pal+$21, #%%3210

                rdlong  pal+$22, addr           '  +0 =
                cmp     pal+$22, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$23, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$23, #%%3210        '  -4   WHOP    128..143


                rdlong  pal+$24, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$24, #%%3210
                waitvid pal+$25, #%%3210

                rdlong  pal+$26, addr           '  +0 =
                cmp     pal+$26, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$27, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$27, #%%3210        '  -4   WHOP    144..159


                rdlong  pal+$28, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$28, #%%3210
                waitvid pal+$29, #%%3210

                rdlong  pal+$2A, addr           '  +0 =
                cmp     pal+$2A, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$2B, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$2B, #%%3210        '  -4   WHOP    160..175


                rdlong  pal+$2C, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$2C, #%%3210
                waitvid pal+$2D, #%%3210

                rdlong  pal+$2E, addr           '  +0 =
                cmp     pal+$2E, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$2F, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$2F, #%%3210        '  -4   WHOP    176..191


                rdlong  pal+$30, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$30, #%%3210
                waitvid pal+$31, #%%3210

                rdlong  pal+$32, addr           '  +0 =
                cmp     pal+$32, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$33, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$33, #%%3210        '  -4   WHOP    192..207


                rdlong  pal+$34, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$34, #%%3210
                waitvid pal+$35, #%%3210

                rdlong  pal+$36, addr           '  +0 =
                cmp     pal+$36, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$37, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$37, #%%3210        '  -4   WHOP    208..223


                rdlong  pal+$38, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$38, #%%3210
                waitvid pal+$39, #%%3210

                rdlong  pal+$3A, addr           '  +0 =
                cmp     pal+$3A, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$3B, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$3B, #%%3210        '  -4   WHOP    224..239


                rdlong  pal+$3C, addr           '  +0 =
                add     addr, #8                '  +8   skip 4n+1
                waitvid pal+$3C, #%%3210
                waitvid pal+$3D, #%%3210

                rdlong  pal+$3E, addr           '  +0 =
                cmp     pal+$3E, #%%3210        '  +8   WHOP
                add     addr, #4                '  -4

                rdlong  pal+$3F, addr           '  +0 =
                add     addr, #4                '  +8
                cmp     pal+$3F, #%%3210        '  -4   WHOP    240..255

                add     lcnt, #1                ' line has been fetched

                jmp     #hsync                  ' chain call

emit_12
                mov     vcfg, vid_vcfg
                or      outa, reg_outa

                movd    :vid, #pal+0            ' restore initial settings
                mov     ecnt, #64 -1            ' quad pixel count

                mov     vscl, hvis              ' pixel timing
:vid            waitvid 0-0, #%%3210            ' send scanline
                add     $-1, dst1               ' advance dst
                djnz    ecnt, #:vid

                waitvid pal+63, #%%3210
                
                jmp     #hsync                  ' chain call

emit_3
                mov     vcfg, vid_vcfg
                or      outa, reg_outa

                movd    :vid, #pal+0            ' restore initial settings
                mov     ecnt, #64 -1            ' quad pixel count

                mov     vscl, hvis              ' pixel timing
:vid            waitvid 0-0, #%%3210            ' send scanline
                add     $-1, dst1               ' advance dst
                djnz    ecnt, #:vid

                waitvid pal+63, #%%3210
                
                jmpret  zero, #hsync nr,wc      ' chain call (start loading)    (%%)

' initialised data and/or presets

idle            long    hv_idle
sync            long    hv_idle ^ $0200

reg_dira        long    %0000_0000_0000_0000_0000_0000_1111_1111
reg_outa        long    %0000_0000_0000_0000_0000_0011_0000_0000

sync_vcfg       long    %0_01_1_0_0_000_00000100000_011_0_00000011 '%0_01_1_0_0_000_00000100000_001_0_00000011 ' P24,P25 Vsync, Hsync
vid_vcfg        long    %0_01_1_0_0_000_00000100000_001_0_11111111 ' P16-P23 RRRGGGBB data

                        
hvis            long      5 << 12 | 20          '   5/20
slow            long    170 << 12 | 370         ' 170/370
line            long      0 << 12 | 1280        ' 256/1280

mask            long    vpin << (vgrp * 8)      ' pin I/O setup

dst1            long    1 << 9                  ' dst +/-= 1

blnk            long    -4
base            long    0
vres            long    256

' uninitialised data and/or temporaries

href            res     1                       ' hub window reference

ecnt            res     1                       ' element count
lcnt            res     1                       ' line counter
scnt            res     1                       ' scanlines
addr            res     1                       ' colour buffer reference

pal             res     64                      ' colour buffer

                fit     $1F0