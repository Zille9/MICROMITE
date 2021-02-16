{{

        SLUG - (S)imple (L)ow-res (U)tility code for (G)aming
        v0.4
        
        v0.4 - Added support for 256 color VGA (Roadster)
        v0.3 - Changes to support VGA
        v0.2 - Changed to 8x8 sprites, moved VCFG/DIRA constants to renderer
        v0.1 - Initial release
        
}}
CON 
  
'** end CON configuration ***

  HORIZONTAL_PIXELS = 128
  VERTICAL_PIXELS   = 96

  BACK_SIZE      = 64                      '8 x 8 = 64 bytes
  SPRITE_COUNT   = 8                       'number of sprites
  SPRITE_COUNT_0 = SPRITE_COUNT - 1        'number of sprites, 0 based

  #0, SPRITE_VISIBLE, SPRITE_X, SPRITE_Y,{SPRITE_IMG,}SPRITE_SIZE

VAR
  byte displayb[HORIZONTAL_PIXELS * VERTICAL_PIXELS]   'allocate display buffer in RAM
  byte backb[BACK_SIZE * SPRITE_COUNT]                 'back buffer (when sprites are drawn)
  byte spriteb[SPRITE_SIZE * SPRITE_COUNT]

  long seed

  'interface variables
  long draw_cmd
  long draw_scrptr
  long draw_datptr
  long draw_bkgptr

  'pointer to the rendering cog
  long draw_cog
  
  'pointer to video status
  long vstatus

  byte sprites[SPRITE_COUNT * 64 + 1] ' 6 sprites (384 / 64) + 1 extra byte
  byte columns,rows,textcounter


OBJ
    vga   : "SLUG_VGA_8bit" 
        
PUB Start(Cmode)
   vga.start(CMode, @displayb, @vstatus)
   seed := cnt
   columns:=rows:=textcounter:=0
   InitRendering
  
' //////////////////////////////////////////////////////////////////
' Random Number Generation Routine
' //////////////////////////////////////////////////////////////////
PUB rand
    seed := seed * 1103515245 + 12345 + CNT / 7777
    return seed

'------------------------------------------------------------

pub InitRendering | ok
    draw_cmd := 0

    ok := draw_cog := cognew(@entry, @draw_cmd) + 1       ' start the sprite rendering cog
    return ok
        
pub Cls (color) | k
  BYTEFILL(@displayb, color, 12288)

pub plot(x,y,c)

      if x > 127
         x:=127
      if y > 90
         y:=90
      displayb[y<<7+x] := c          '(y * HORIZONTAL_PIXELS) + x

pub DrawChar(x,y,ch,c) | ptr, fx, fy, b
   ptr := @font + (ch * 2)
   fx := x
   fy := y
    
   repeat 2
      repeat b from 0 to 7
        if (byte[ptr]&(|<(7-b)))
           plot(fx,fy, c)          
        fx++
        if (b == 3)
           fx := x
           fy++
      fx := x
      fy++      
      ptr++

pub Print(x,y,s,c)
  repeat while byte[s][0]
    DrawChar(x,y,byte[s][0]-32,c)
    s++
    x+=4

PUB dec(x, y, value, c) | i

  i := 1_000_000_000

  repeat 10
    if value => i
      DrawChar(x,y,value / i + 16,c)
      x += 4
      value //= i
      result~~
    elseif result or i == 1
      DrawChar(x,y,16,c)
      x += 4
    i /= 10   

pub DrawTile(x,y,n) | i
    repeat i from 0 to 7
     BYTEMOVE(screen(x,y+i), @tiles[i<<3]+(n<<6), 8)

pub Screen(x,y)
  result := @displayb +(y<<7)+x                          '(y * HORIZONTAL_PIXELS) + x

pub AddSprite(sprite_no) | ptr
   ptr := @spriteb + (sprite_no * SPRITE_SIZE)          ' [kuroneko] may not be po2
   byte[ptr][SPRITE_VISIBLE] := 1

pub HideSprite(sprite_no) | ptr
   ptr := @spriteb + (sprite_no * SPRITE_SIZE)          ' [kuroneko] may not be po2
   byte[ptr][SPRITE_VISIBLE] := 0
   
pub SetSprite(sprite_no, spr_x, spr_y, spr_img{ignored}) | ptr
   ptr := @spriteb + (sprite_no * SPRITE_SIZE)          ' [kuroneko] may not be po2
   byte[ptr][SPRITE_X] := spr_x
   byte[ptr][SPRITE_Y] := spr_y
'  byte[ptr][SPRITE_IMG] := spr_img
        
pub RestoreBackdrop |i, ptr
   ptr := @spriteb
   repeat i from 0 to SPRITE_COUNT_0
     if byte[ptr][SPRITE_VISIBLE] == 1
         RestoreBackground(byte[ptr][SPRITE_X], byte[ptr][SPRITE_Y], i)
     ptr += SPRITE_SIZE    
                
pub RenderSprites | i, ptr

   ptr := @spriteb + constant(SPRITE_COUNT_0 * SPRITE_SIZE) 'start at the end of the sprite buffer
   repeat i from SPRITE_COUNT_0 to 0 
      if byte[ptr][SPRITE_VISIBLE] == 1
         'get the background where the player would be
         GetBackground(byte[ptr][SPRITE_X], byte[ptr][SPRITE_Y], i)      
         'draw the sprite
         DrawSprite(byte[ptr][SPRITE_X], byte[ptr][SPRITE_Y], i)
      ptr -= SPRITE_SIZE
          
pub SpriteCollision (spr1, spr2) | ptr1, ptr2
    ptr1 := @spriteb + (spr1 * SPRITE_SIZE)             ' [kuroneko] may not be po2
    ptr2 := @spriteb + (spr2 * SPRITE_SIZE)             ' [kuroneko] may not be po2
    'test for collision using bounding box
    if ((byte[ptr1][SPRITE_Y] + 8) < byte[ptr2][SPRITE_Y])
      return 0
    if (byte[ptr1][SPRITE_Y] > (byte[ptr2][SPRITE_Y]+8))
      return 0
    if ((byte[ptr1][SPRITE_X] + 8) < byte[ptr2][SPRITE_X])
      return 0
    if (byte[ptr1][SPRITE_X] > (byte[ptr2][SPRITE_X] + 8))
      return 0

    return 1
 
pub VWait
   'wait for the vsync event to render the graphics
   repeat until vstatus <> 0
   vstatus := 0
 
pub DrawSprite(x, y, n)                  
    repeat while draw_cmd <> 0                          ' wait if presently busy
    draw_scrptr := @displayb + (y<<7)+x                 ' determine screen location
    draw_datptr := @sprites + (n<<6)                    ' right now at 128; 8x8 = 64
    draw_cmd    := 1                                    ' set the command to trigger PASM

pub GetBackground(x,y,b)
    repeat while draw_cmd <> 0
    draw_scrptr := @displayb +(y<<7)+x
    draw_bkgptr := @backb+(b<<6)                        '8x8 = 64
    draw_cmd    := 2

pub RestoreBackground(x,y,b)
    repeat while draw_cmd <> 0
    draw_scrptr := @displayb +(y<<7)+x
    draw_bkgptr := @backb+(b<<6)                        '8x8 = 64
    draw_cmd    := 3   

pub peek(x, y)
   return displayb[y<<7+x]

PUB redefine (spriteln,dota,dotb,dotc,dotd,dote,dotf,dotg,doth)

   sprites[spriteln*8]:=dota
   sprites[spriteln*8+1]:=dotb
   sprites[spriteln*8+2]:=dotc
   sprites[spriteln*8+3]:=dotd
   sprites[spriteln*8+4]:=dote
   sprites[spriteln*8+5]:=dotf
   sprites[spriteln*8+6]:=dotg
   sprites[spriteln*8+7]:=doth

PUB OUT (charac,textcolor,backcolor)

           '' Primitive text display.  Just enough for very basic functions with existing font.
           if charac > 32 and charac < 91
              charac:=charac-32

           if charac > 96 and charac < 123  '' Convert alpha characters
              charac:=charac-64

           if charac == 13
              charac:=0
              columns++
              columns++
              columns++
              columns++
              columns++
              rows:=1
              textcounter:=0

           if charac == 32                    '' Convert Space Character
              charac := 0
              DrawChar(rows,columns,0,textcolor)
              rows++
              rows++
              rows++
              rows++

           if charac == 8 and textcounter > 0
              charac := 0
              rows--
              rows--
              rows--
              rows--
              DrawChar(rows,columns,64,backcolor)
              rows--
              rows--
              rows--
              rows--
              textcounter--

           if rows > 125
              columns++
              columns++
              columns++
              columns++
              columns++
              rows:=1
              textcounter:=0

           if charac > 12

              if columns > 93
                 cls(backcolor)
                 columns:=0
                 rows:=1
              DrawChar(rows,columns,charac,textcolor)
              rows++
              rows++
              rows++
              rows++

DAT
font    byte %00000000 '(space)
        byte %00000000

        byte %01000100 '!
        byte %00000100

        byte %10100000 '"
        byte %00000000

        byte %10101110 '#
        byte %11101010

        byte %01001110 '$
        byte %11000110

        byte %10100010 '%
        byte %01001010

        byte %01101010 '&
        byte %11000110

        byte %00100000 '
        byte %00000000

        byte %01001000 '(
        byte %10000100

        byte %10000100 ')
        byte %01001000

        byte %10100100 '*
        byte %10100000

        byte %01001110 '+
        byte %01000000

        byte %00000000 ',
        byte %01001000
        
        byte %00001110 '-
        byte %00000000

        byte %00000000 '.
        byte %00000100

        byte %00100100 '/
        byte %01001000

        byte %11001010 '0
        byte %10100110

        byte %01001100 '1
        byte %01001110

        byte %11100110 '2
        byte %10001110

        byte %11100110 '3
        byte %00101110

        byte %10101110 '4
        byte %00100010

        byte %11101000 '5
        byte %01101110

        byte %01101000 '6
        byte %11101110

        byte %11100010 '7
        byte %01000100

        byte %11001100 '8
        byte %01100110

        byte %11101110 '9
        byte %00100010

        byte %01000000 ':
        byte %01000000

        byte %01000000 ';
        byte %01001000

        byte %01001000 '<
        byte %01000000

        byte %11100000 '=
        byte %11100000

        byte %10000100 '>
        byte %10000000

        byte %11100010 '?
        byte %00000100

        byte %11101010 '@
        byte %10001110
   
        byte %01001010 'A
        byte %11101010

        byte %11101100 'B
        byte %10101110

        byte %01101000 'C
        byte %10000110

        byte %11001010 'D
        byte %10101100

        byte %11101100 'E
        byte %10001110

        byte %11101100 'F
        byte %10001000

        byte %01101000 'G
        byte %10100110

        byte %10101110 'H
        byte %10101010

        byte %11100100 'I
        byte %01001110

        byte %00100010 'J
        byte %10100100

        byte %10101100 'K
        byte %10101010

        byte %10001000 'L
        byte %10001110

        byte %10101110 'M
        byte %10101010

        byte %01101010 'N
        byte %10101010

        byte %01001010 'O
        byte %10100100

        byte %11101110 'P
        byte %10001000

        byte %11101010 'Q
        byte %11000110

        byte %11101010 'R
        byte %11001010

        byte %11101000 'S
        byte %01101110

        byte %11100100 'T
        byte %01000100

        byte %10101010 'U
        byte %10101100

        byte %10101010 'V
        byte %10100100

        byte %10101010 'W
        byte %11101010

        byte %10100100 'X
        byte %10101010

        byte %10100100 'Y
        byte %01000100

        byte %11100010 'Z
        byte %01001110

        byte %11001000 '[
        byte %10001100

        byte %10000100 '\
        byte %01000010

        byte %01100010 ']
        byte %00100110

        byte %01001010 '^
        byte %00000000

        byte %00000000 '_
        byte %00001110

        byte %11111111 '_
        byte %11111111

tiles   byte 'file "tiles.dat"


'--- start of PASM code -----------------------------------------------------------
              org      0
        
entry         mov      tmp1, par                        'retrieve the parameters
              mov      cmdptr, tmp1                     'command pointer
              add      tmp1, #4
              mov      scrptr, tmp1                     'screen pointer
              add      tmp1, #4
              mov      datptr, tmp1                     'data pointer
              add      tmp1, #4
              mov      bkgptr, tmp1                     'background pointer
                           
getcmd                                                  'main loop: look for a command
              rdlong   tmp1, cmdptr    wz
      if_z    jmp      #getcmd
                                                        'check the command
checkcmd
              cmp      tmp1, #1        wz               'if it is 1, then execute the draw command
      if_e    jmp      #cmddraw
              cmp      tmp1, #2        wz               'if it is 2, then execute the get command
      if_e    jmp      #cmdget
              cmp      tmp1, #3        wz               'if it is 3, then execute the put command
      if_e    jmp      #cmdput

cmddone       mov      tmp1, #0                         'reset the command pointer to 0
              wrlong   tmp1, cmdptr
              
              jmp      #getcmd              

'draw at a location ----------------------------------------------------------------
cmddraw
              rdlong   tmp2, scrptr                     'read current screen pointer into temp varialbe
              rdlong   tmp3, datptr                     'read current data pointer into temp variable
              mov      cnty, #8
v_loop
              mov      cntx, #8
h_loop
              rdbyte   tmp1, tmp3
              cmp      tmp1, #0       wz                'test for the transparent color ($00)
     if_e     jmp      #h_loop_skip                     'if it is, skip writing
              
              wrbyte   tmp1, tmp2                       'write to current screen location
h_loop_skip
              add      tmp2, #1                         'advance the pointer
              add      tmp3, #1               
              djnz     cntx, #h_loop

              add      tmp2, #120                      'otherwise, add in an entire screen line less the last 8 pixels (128-8)
              djnz     cnty, #v_loop

              jmp      #cmddone

'get pixels at a location -----------------------------------------------------------
cmdget
              rdlong   tmp2, scrptr                    'read the current screen pointer to a temp variable
              rdlong   tmp3, bkgptr                    'read the current background pointer to a temp variable
              mov      cnty, #8
get_v_loop
              mov      cntx, #8
get_h_loop              
              rdbyte   tmp1, tmp2
              add      tmp2, #1
              wrbyte   tmp1, tmp3
              add      tmp3, #1
              djnz     cntx, #get_h_loop

              add      tmp2, #120                      'add in an entire screen line less the last 8 pixels (128-8)
              djnz     cnty, #get_v_loop
         
              jmp      #cmddone

'put pixels at a location -----------------------------------------------------------
cmdput
              rdlong   tmp2, scrptr                    'read the current screen pointer to a temp variable
              rdlong   tmp3, bkgptr                    'read the current background pointer to a temp variable
              mov      cnty, #8
put_v_loop
              mov      cntx, #8
put_h_loop              
              rdbyte   tmp1, tmp3
              add      tmp3, #1
              wrbyte   tmp1, tmp2
              add      tmp2, #1
              djnz     cntx, #put_h_loop

              add      tmp2, #120                      'add in an entire screen line less the last 8 pixels (128-8)
              djnz     cnty, #put_v_loop
         
              jmp      #cmddone
                    
' --------------------------------------------------------------------------------------------------
bufbyte          long    $2780                           '10112
bufbyte2         long    $27FC                           '10240 - 4 (to align correctly)
buflong          long    $9E0                            '2528 

cmdptr           res     1                               ' command pointer
scrptr           res     1                               ' screen pointer
datptr           res     1                               ' data pointer
bkgptr           res     1                               ' background pointer

cntx             res     1                               ' x counter
cnty             res     1                               ' y counter

tmp1             res     1                               ' work vars
tmp2             res     1
tmp3             res     1

                 fit     492
{{

                            TERMS OF USE: MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}} 
