''
'' VGA driver 320x256 (single cog) - video driver and pixel generator
''
''        Author: Marko Lukat
'' Last modified: 2013/04/22
''       Version: 0.10
''
'' long[par][0]:  screen: [!Z]:addr = 16:16 -> zero (accepted), 4n
'' long[par][1]: colours: [!Z]:addr = 16:16 -> zero (accepted)
'' long[par][2]: palette: [!Z]:addr = 16:16 -> zero (accepted), 4n (runtime update)
'' long[par][3]: frame indicator
''
'' acknowledgements
'' - loader code based on work done by Phil Pilgrim (PhiPi)
''
'' 20130420: initial version (1280x1024@60Hz timing, %00 sync locked)
'' 20130422: added palette update code
''
OBJ
  system: "core.con.system"
    
PUB null
'' This is not a top level object.

PUB init(ID, mailbox)
                                      
  return system.launch(ID, @driver, mailbox)

DAT             org     0                       ' cog binary header

header_2048     long    system#ID_2             ' magic number for a cog binary
                word    header_size             ' header size
                word    system#MAPPING          ' flags
                word    0, 0                    ' start register, register count

                word    @__table - @header_2048 ' translation table byte offset

header_size     fit     16
                
DAT             org     0

driver          jmpret  $, #setup               '  -4   once

                mov     dira, mask              ' drive outputs

' Setup complete, enter display loop.
                
'               mov     ecnt, #1
vsync           call    #blank                  ' front porch
'               djnz    ecnt, #$-1

                xor     sync, #$0101            ' active

                mov     ecnt, #3
                call    #blank                  ' vertical sync
                djnz    ecnt, #$-1

                xor     sync, #$0101            ' inactive

' Put some distance between vertical blank indication and palette request fetch.

                rdlong  updt, updt_ wz          ' fetch palette update request
        if_nz   wrlong  zero, updt_             ' acknowledge

                mov     ecnt, #38 -32
                call    #blank                  ' back porch
                djnz    ecnt, #$-1

' The last 32 invisible lines are used for fetching colour. This will cause
' pixel updates but they are not emitted so that's OK.

                mov     zwei, plte              ' reset colour buffer

                mov     scnt, #32               ' scnt is key value ...
                call    #blank
                call    #fetch                  ' ... for colour fetch
                djnz    scnt, #$-2

' Vertical sync chain done, do visible area.

                mov     eins, scrn              ' reset screen buffer
                mov     scnt, resy              ' actual scanline count (x4)

:loop           call    #fetch                  ' 4n: pixels, else colour
                call    #emit                     
                call    #hsync

                djnz    scnt, #:loop            ' for all scanlines

                wrlong  cnt, fcnt_              ' announce vertical blank

                jmp     #vsync                  ' next frame


blank           mov     vscl, line              ' 256/960
                waitvid sync, #%0000

                cmp     updt, #0 wz             ' enabled?
        if_e    jmp     #hsync                  ' nothing to do

                movd    :one, #pf+15            ' |
                movd    :two, #pf+14            ' prime destination

                shr     updt, #1{/2}            ' added twice
                mov     phsb, #(16 + 8)* 4 -1   ' byte count (8n + 7)
                
:one            rdlong  0-0, phsb               ' |
                sub     $-1, dst2               ' |
                sub     phsb, #7 wz             ' |
:two            rdlong  0-0, phsb               ' |
                sub     $-1, dst2               ' sub #7/djnz (Thanks Phil!)
        if_nz   djnz    phsb, #:one             ' load 16+8 palette entries

                mov     updt, #0                ' done, disable

hsync           mov     vscl, slow              '   6/306
                waitvid sync, slow_value

                mov     cnt, cnt                ' record sync point                     (##)
                add     cnt, #9{14} + 260       '                                       (##)

                mov     vcfg, vcfg_sync         ' switch back to sync mode
hsync_ret
blank_ret       ret


fetch           mov     vier, scnt              ' |
                and     vier, #%11111 wz        ' isolate scanline index
        if_z    movd    :cpy, #two+0            ' prime call (reset)

                test    vier, #%11 wz           ' 4n?
        if_z    jmp     #xfer

                cmp     vier, #6 wc             ' |
        if_c    jmp     fetch_ret               ' stop after 20 invocations
        
                mov     ecnt, #2                ' time for two characters
                
:loop           rdbyte  drei, zwei              '  +0 = fetch colour
                mov     vier, drei              '       split
                and     vier, #%111             '       background

                add     vier, #pb               '  +0 = final index (bg)
                movs    :one, vier              '       prime call
                test    drei, #%10000000 wc     '       test blink mode
:one            mov     vier, 0-0               '       1st palette entry

                shr     drei, #3                '  +0 = foreground
                and     drei, #%00001111        '       limit to 16 entries
                add     drei, #pf               '       final index (fg)
                movs    :two, drei              '       prime call

                add     zwei, #1                '  +0 = advance address
:two            or      vier, 0-0               '       2nd palette entry
                test    blnk, cnt wz            '       test flash interval
    if_c_and_z  rol     vier, #8                '       fg == bg

:cpy            mov     two+0, vier             '  +0 = transfer to hidden palette
                add     $-1, dst1               '       advance index

                djnz    ecnt, #:loop            '  +8   for each character
                jmp     fetch_ret
                
xfer            rdlong  pix+0, eins             '   0..31
                add     eins, #4
                rdlong  pix+1, eins             '  32..63
                add     eins, #4
                rdlong  pix+2, eins             '  64..95
                add     eins, #4
                rdlong  pix+3, eins             '  96..127
                add     eins, #4
                rdlong  pix+4, eins             ' 128..159
                add     eins, #4
                rdlong  pix+5, eins             ' 160..191
                add     eins, #4
                rdlong  pix+6, eins             ' 192..223
                add     eins, #4
                rdlong  pix+7, eins             ' 224..255
                add     eins, #4
                rdlong  pix+8, eins             ' 256..287
                add     eins, #4
                rdlong  pix+9, eins             ' 288..319
                add     eins, #4

fetch_ret       ret


emit            waitcnt cnt, #0                 ' re-sync after back porch              (##)

                mov     vcfg, vcfg_norm         ' disconnect sync from video h/w
                mov     vscl, hvis              ' pixel timing

                test    scnt, #%00011111 wz     ' 32n

        if_z    mov     one+$0, two+$0
                waitvid one+$0, pix+0
                ror     pix+0, #8
        if_z    mov     one+$1, two+$1
                waitvid one+$1, pix+0
                ror     pix+0, #8
        if_z    mov     one+$2, two+$2
                waitvid one+$2, pix+0
                ror     pix+0, #8
        if_z    mov     one+$3, two+$3
                waitvid one+$3, pix+0
                ror     pix+0, #8    

        if_z    mov     one+$4, two+$4
                waitvid one+$4, pix+1
                ror     pix+1, #8
        if_z    mov     one+$5, two+$5
                waitvid one+$5, pix+1
                ror     pix+1, #8
        if_z    mov     one+$6, two+$6
                waitvid one+$6, pix+1
                ror     pix+1, #8
        if_z    mov     one+$7, two+$7
                waitvid one+$7, pix+1
                ror     pix+1, #8    

        if_z    mov     one+$8, two+$8
                waitvid one+$8, pix+2
                ror     pix+2, #8
        if_z    mov     one+$9, two+$9
                waitvid one+$9, pix+2
                ror     pix+2, #8
        if_z    mov     one+10, two+10
                waitvid one+10, pix+2
                ror     pix+2, #8
        if_z    mov     one+11, two+11
                waitvid one+11, pix+2
                ror     pix+2, #8    

        if_z    mov     one+12, two+12
                waitvid one+12, pix+3 
                ror     pix+3, #8
        if_z    mov     one+13, two+13
                waitvid one+13, pix+3 
                ror     pix+3, #8
        if_z    mov     one+14, two+14
                waitvid one+14, pix+3 
                ror     pix+3, #8
        if_z    mov     one+15, two+15
                waitvid one+15, pix+3 
                ror     pix+3, #8     

        if_z    mov     one+16, two+16
                waitvid one+16, pix+4 
                ror     pix+4, #8
        if_z    mov     one+17, two+17
                waitvid one+17, pix+4 
                ror     pix+4, #8
        if_z    mov     one+18, two+18
                waitvid one+18, pix+4 
                ror     pix+4, #8
        if_z    mov     one+19, two+19
                waitvid one+19, pix+4 
                ror     pix+4, #8     

        if_z    mov     one+20, two+20
                waitvid one+20, pix+5 
                ror     pix+5, #8
        if_z    mov     one+21, two+21
                waitvid one+21, pix+5 
                ror     pix+5, #8
        if_z    mov     one+22, two+22
                waitvid one+22, pix+5 
                ror     pix+5, #8
        if_z    mov     one+23, two+23
                waitvid one+23, pix+5 
                ror     pix+5, #8     

        if_z    mov     one+24, two+24
                waitvid one+24, pix+6 
                ror     pix+6, #8
        if_z    mov     one+25, two+25
                waitvid one+25, pix+6 
                ror     pix+6, #8
        if_z    mov     one+26, two+26
                waitvid one+26, pix+6 
                ror     pix+6, #8
        if_z    mov     one+27, two+27
                waitvid one+27, pix+6 
                ror     pix+6, #8     

        if_z    mov     one+28, two+28
                waitvid one+28, pix+7 
                ror     pix+7, #8
        if_z    mov     one+29, two+29
                waitvid one+29, pix+7 
                ror     pix+7, #8
        if_z    mov     one+30, two+30
                waitvid one+30, pix+7 
                ror     pix+7, #8
        if_z    mov     one+31, two+31
                waitvid one+31, pix+7 
                ror     pix+7, #8     

        if_z    mov     one+32, two+32
                waitvid one+32, pix+8 
                ror     pix+8, #8
        if_z    mov     one+33, two+33
                waitvid one+33, pix+8 
                ror     pix+8, #8
        if_z    mov     one+34, two+34
                waitvid one+34, pix+8 
                ror     pix+8, #8
        if_z    mov     one+35, two+35
                waitvid one+35, pix+8 
                ror     pix+8, #8     

        if_z    mov     one+36, two+36
                waitvid one+36, pix+9 
                ror     pix+9, #8
        if_z    mov     one+37, two+37
                waitvid one+37, pix+9 
                ror     pix+9, #8
        if_z    mov     one+38, two+38
                waitvid one+38, pix+9 
                ror     pix+9, #8
        if_z    mov     one+39, two+39
                waitvid one+39, pix+9 
                ror     pix+9, #8     

emit_ret        ret

' initialised data and/or presets

sync            long    $0200                   ' locked to %00 {%hv}
                        
slow_value      long    $000FFFC0               ' 31/14/6
slow            long    6 << 12 | 306           '   6/306
hvis            long    3 << 12 | 24            '   3/24
line            long    0 << 12 | 960           ' 256/960

vcfg_norm       long    %0_01_0_00_000 << 23 | vgrp << 9 | vpin
vcfg_sync       long    %0_01_0_00_000 << 23 | sgrp << 9 | %11

mask            long    vpin << (vgrp * 8) | %11 << (sgrp * 8)

dst1            long    1 << 9                  ' dst +/-= 1
dst2            long    2 << 9                  ' dst +/-= 2

scrn_           long    0                       ' |
plte_           long    4                       ' |
updt_           long    8                       ' |
fcnt_           long    12                      ' mailbox addresses (local copy)

resy            long    res_y * 4               ' actual scanlines
blnk            long    |< 25                   ' flashing mask

' Foreground colour is in byte 1, background in 3 and 0.

pb{ackground}   long    $04000004[$8]
pf{oreground}   long    $00002800[16]

' Stuff below is re-purposed for temporary storage.

setup           add     scrn_, par              ' @long[par][0]
                add     plte_, par              ' @long[par][1]
                add     updt_, par              ' @long[par][2]
                add     fcnt_, par              ' @long[par][3]

                rdlong  scrn, scrn_             ' screen buffer                         (%%)
                rdlong  plte, plte_             ' colour buffer                         (%%)

                wrlong  zero, scrn_             ' |
                wrlong  zero, plte_             ' acknowledge

                movi    ctrb, #%0_11111_000     ' LOGIC always (loader support)
                
' Upset video h/w and relatives.

                movi    ctra, #%0_00001_111     ' PLL, VCO/1
                movi    frqa, #%0001_00000      ' 5MHz * 16/1 = 80MHz

                mov     vcfg, vcfg_sync         ' VGA, 2 colour mode
                
' Setup complete, do the heavy lifting upstairs ...

                jmp     %%0                     ' return

' uninitialised data and/or temporaries

                org     setup
                
scrn            res     1                       ' screen buffer reference  < setup +3   (%%)    
plte            res     1                       ' colour buffer reference  < setup +4   (%%)

ecnt            res     1                       ' element count
scnt            res     1                       ' scanlines

pix             res     10                      ' scanline byffer
one             res     40                      ' |
two             res     40                      ' palette buffers

eins            res     1
zwei            res     1
drei            res     1
vier            res     1

tail            fit

DAT                                             ' translation table

__table         word    (@__names - @__table)/2

                word    res_x
                word    res_y
                word    res_m
                
__names         byte    "res_x", 0
                byte    "res_y", 0
                byte    "res_m", 0

CON
  zero    = $1F0                                ' par (dst only)
  updt    = $1FB                                ' frqb
  
  vpin    = $0FC                                ' pin group mask
  vgrp    = 1                                   ' pin group
  sgrp    = 1                                   ' pin group sync

  res_x   = 320                                 ' |
  res_y   = 256                                 ' |
  res_m   = 4                                   ' UI support
  
DAT
