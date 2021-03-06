{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐               
│ Bitmap Engine - 4 Color Version                                                                                             │
│                                                                                                                             │
│ Author: Kwabena W. Agyeman                                                                                                  │                              
│ Updated: 10/18/2009                                                                                                         │
│ Designed For: P8X32A                                                                                                        │
│                                                                                                                             │
│ Copyright (c) 2009 Kwabena W. Agyeman                                                                                       │              
│ See end of file for terms of use.                                                                                           │               
│                                                                                                                             │
│ Driver Info:                                                                                                                │
│                                                                                                                             │
│ The BMPEngine runs a BMP driver in the next free cog on the propeller chip when called.                                     │
│                                                                                                                             │
│ The bitmap driver produces a 640 x 480 @ 60Hz VGA signal which is then scaled to the appropriate resolution.                │
│                                                                                                                             │                                                                                                             
│ The driver, is only guaranteed and tested to work at an 80Mhz system clock or higher. The driver is designed for the P8X32A │
│ so port B will not be operational.                                                                                          │
│                                                                                                                             │
│ Nyamekye,                                                                                                                   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

CON

  ''
  ''     0   1   2   3 Pin Group
  ''                                                  
  ''                      1RΩ
  '' Pin 0,  8, 16, 24 ───────── Vertical Sync
  ''
  ''                      1RΩ
  '' Pin 1,  9, 17, 25 ───────── Horizontal Sync
  ''
  ''                      2RΩ
  '' Pin 2, 10, 18, 26 ──────┳── Blue Video
  ''                            │
  ''                      1RΩ   │
  '' Pin 3, 11, 19, 27 ──────┘
  ''              
  ''                      2RΩ
  '' Pin 4, 12, 20, 28 ──────┳── Green Video
  ''                            │
  ''                      1RΩ   │ 
  '' Pin 5, 13, 21, 29 ──────┘
  ''
  ''                      2RΩ
  '' Pin 6, 14, 22, 30 ──────┳── Red Video
  ''                            │
  ''                      1RΩ   │
  '' Pin 7, 15, 23, 31 ──────┘ 
  ''
  ''                            5V
  ''                            
  ''                            └── 5V
  ''
  ''                            ┌── Vertical Sync Ground
  ''                            
  ''
  ''                            ┌── Hoirzontal Sync Ground
  ''                            
  ''                      
  ''                            ┌── Blue Return
  ''                            
  ''
  ''                            ┌── Green Return
  ''                            
  ''
  ''                            ┌── Red Return
  ''                            

  Pin_Group = 1
          
  Horizontal_Pixels = 320 ' The driver will force this value to be a factor of 640 and divisible by 16.
  Vertical_Pixels = 240 ' The driver will force this value to be a factor of 480.

CON

  ' For use with "changePixelColor".

  #$FC, Light_Grey
  #$A8, Grey
  #$54, Dark_Grey

  #$F0, Light_Yellow
  #$A0, Yellow
  #$50, Dark_Yellow

  #$CC, Light_Purple
  #$88, Purple
  #$44, Dark_Purple

  #$3C, Light_Teal
  #$28, Teal
  #$14, Dark_Teal
  
  #$C0, Light_Red
  #$80, Red
  #$40, Dark_Red

  #$30, Light_Green
  #$20, Green
  #$10, Dark_Green

  #$C, Light_Blue
  #$8, Blue
  #$4, Dark_Blue
  
  #$0, Black

  Horizontal_Scaling = ((((Horizontal_Pixels #> 0) =< 16) & 40) #> (((Horizontal_Pixels #> 0) =< 32) & 20) #> {
                       }(((Horizontal_Pixels #> 0) =< 64) & 10) #> (((Horizontal_Pixels #> 0) =< 80) & 8)  #> {
                       }(((Horizontal_Pixels #> 0) =< 128) & 5) #> (((Horizontal_Pixels #> 0) =< 160) & 4) #> {
                       }(((Horizontal_Pixels #> 0) =< 320) & 2) #> 1)

  Vertical_Scaling = ((((Vertical_Pixels #> 0) =< 1) & 480) #> (((Vertical_Pixels #> 0) =< 2) & 240) #> {
                     }(((Vertical_Pixels #> 0) =< 3) & 160) #> (((Vertical_Pixels #> 0) =< 4) & 120) #> {
                     }(((Vertical_Pixels #> 0) =< 5) & 96)  #> (((Vertical_Pixels #> 0) =< 6) & 80)  #> {
                     }(((Vertical_Pixels #> 0) =< 8) & 60)  #> (((Vertical_Pixels #> 0) =< 10) & 48) #> {
                     }(((Vertical_Pixels #> 0) =< 12) & 40) #> (((Vertical_Pixels #> 0) =< 15) & 32) #> {
                     }(((Vertical_Pixels #> 0) =< 16) & 30) #> (((Vertical_Pixels #> 0) =< 20) & 24) #> {
                     }(((Vertical_Pixels #> 0) =< 24) & 20) #> (((Vertical_Pixels #> 0) =< 30) & 16) #> {
                     }(((Vertical_Pixels #> 0) =< 32) & 15) #> (((Vertical_Pixels #> 0) =< 40) & 12) #> {
                     }(((Vertical_Pixels #> 0) =< 48) & 10) #> (((Vertical_Pixels #> 0) =< 60) & 8)  #> {
                     }(((Vertical_Pixels #> 0) =< 80) & 6)  #> (((Vertical_Pixels #> 0) =< 96) & 5)  #> {
                     }(((Vertical_Pixels #> 0) =< 120) & 4) #> (((Vertical_Pixels #> 0) =< 160) & 3) #> {
                     }(((Vertical_Pixels #> 0) =< 240) & 2) #> 1)

  Horizontal_Resolution = (640 / Horizontal_Scaling) ' This is the final computed horizontal pixel resolution.
  Vertical_Resolution = (480 / Vertical_Scaling) ' This is the final computed vertical pixel resolution.

  Display_Buffer_size = ((Horizontal_Resolution * Vertical_Resolution) / 16) ' This is the display buffer size in longs.
  
VAR

  long displayBuffer[Display_Buffer_size]

  long pixelColor

  byte syncIndicator
  byte displayIndicator

  word displayAccumulator 
dat
font byte $00,$00,$00,$00,$00,$00,$00,$00       'Space  32
     byte $0C,$0C,$0C,$0C,$0C,$00,$0C,$00       '!      33
     byte $EE,$CC,$66,$00,$00,$00,$00,$00       ' "     34
     byte $6C,$6C,$7F,$36,$7F,$1B,$1B,$00       '# 35
     byte $18,$7C,$36,$7C,$D8,$D8,$7E,$18       '$ 36
     byte $00,$63,$33,$18,$0C,$66,$63,$00       '% 37
     byte $1C,$36,$1C,$6E,$3B,$33,$6E,$00       '& 38
     byte $38,$30,$18,$00,$00,$00,$00,$00       ' ' 39
     byte $18,$0C,$06,$06,$06,$0C,$18,$00       '( 40
     byte $06,$0C,$18,$18,$18,$0C,$06,$00       ') 41
     byte $00,$66,$3C,$FF,$3C,$66,$00,$00       '* 42
     byte $00,$0C,$0C,$3F,$0C,$0C,$00,$00       '+ 43
     byte $00,$00,$00,$00,$00,$38,$30,$18       ', 44
     byte $00,$00,$00,$7F,$00,$00,$00,$00       '- 45
     byte $00,$00,$00,$00,$00,$0C,$0C,$00       '. 46
     byte $60,$30,$18,$0C,$06,$03,$01,$00       '/ 47
     byte $3E,$63,$73,$7B,$6F,$67,$3E,$00       '0 48
     byte $0C,$0E,$0C,$0C,$0C,$0C,$3F,$00       '1 49
     byte $1E,$33,$30,$1C,$06,$33,$3F,$00       '2 50
     byte $3F,$18,$0C,$1E,$30,$33,$1E,$00       '3 51
     byte $38,$3C,$36,$33,$7F,$30,$78,$00       '4 52
     byte $3F,$03,$1F,$30,$30,$33,$1E,$00       '5 53
     byte $1C,$06,$03,$1F,$33,$33,$1E,$00       '6 54
     byte $3F,$33,$30,$18,$0C,$0C,$0C,$00       '7 55
     byte $1E,$33,$33,$1E,$33,$33,$1E,$00       '8 56
     byte $1E,$33,$33,$3E,$30,$18,$0E,$00       '9 57
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$00       ': 58
     byte $00,$00,$0C,$0C,$00,$0C,$0C,$06       '; 59
     byte $18,$0C,$06,$03,$06,$0C,$18,$00       '< 60
     byte $00,$00,$3F,$00,$3F,$00,$00,$00       '= 61
     byte $06,$0C,$18,$30,$18,$0C,$06,$00       '> 62
     byte $1E,$33,$30,$18,$0C,$00,$0C,$00       '? 63
     byte $3E,$63,$7B,$7B,$7B,$03,$1E,$00       '@ 64
     byte $0C,$1E,$33,$33,$3F,$33,$33,$00       'A 65
     byte $3F,$66,$66,$3E,$66,$66,$3F,$00       'B 66
     byte $3C,$66,$03,$03,$03,$66,$3C,$00       'C 67
     byte $1F,$36,$66,$66,$66,$36,$1F,$00       'D 68
     byte $7F,$46,$16,$1E,$16,$46,$7F,$00       'E 69
     byte $7F,$46,$16,$1E,$16,$06,$0F,$00       'F 70
     byte $3C,$66,$03,$03,$73,$66,$3C,$00       'G 71
     byte $33,$33,$33,$3F,$33,$33,$33,$00       'H 72
     byte $1E,$0C,$0C,$0C,$0C,$0C,$1E,$00       'I 73
     byte $78,$30,$30,$30,$33,$33,$1E,$00       'J 74
     byte $67,$66,$36,$0E,$36,$66,$67,$00       'K 75
     byte $0F,$06,$06,$06,$46,$66,$7F,$00       'L 76
     byte $63,$77,$7F,$6B,$63,$63,$63,$00       'M 77
     byte $63,$67,$6F,$7B,$73,$63,$63,$00       'N 78
     byte $1C,$36,$63,$63,$63,$36,$1C,$00       'O 79
     byte $3F,$66,$66,$3E,$06,$06,$0F,$00       'P 80
     byte $1E,$33,$33,$33,$33,$3B,$1E,$38       'Q 81
     byte $3F,$66,$66,$3E,$36,$66,$67,$00       'R 82
     byte $3E,$63,$0F,$3C,$70,$63,$3E,$00       'S 83
     byte $3F,$2D,$0C,$0C,$0C,$0C,$1E,$00       'T 84
     byte $33,$33,$33,$33,$33,$33,$1E,$00       'U 85
     byte $33,$33,$33,$1E,$1E,$0C,$0C,$00       'V 86
     byte $63,$63,$63,$6B,$7F,$77,$63,$00       'W 87
     byte $63,$63,$36,$1C,$36,$63,$63,$00       'X 88
     byte $33,$33,$33,$1E,$0C,$0C,$1E,$00       'Y 89
     byte $7F,$63,$31,$18,$4C,$66,$7F,$00       'Z 90
     byte $3C,$0C,$0C,$0C,$0C,$0C,$3C,$00       '[ 91
     byte $18,$18,$18,$18,$18,$18,$18,$00       '| 92
     byte $3C,$30,$30,$30,$30,$30,$3C,$00       '] 93
     byte $08,$1C,$36,$63,$00,$00,$00,$00       '^ 94
     byte $00,$00,$00,$00,$00,$00,$00,$FF       '_ 95
     byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF       'Cursor 96
     byte $00,$00,$1E,$30,$3E,$33,$6E,$00       'a 97
     byte $07,$06,$3E,$66,$66,$66,$3B,$00       'b 98
     byte $00,$00,$1E,$33,$03,$33,$1E,$00       'c 99
     byte $38,$30,$3E,$33,$33,$33,$6E,$00       'd 100
     byte $00,$00,$1E,$33,$3F,$03,$1E,$00       'e 101
     byte $1C,$36,$06,$0F,$06,$06,$0F,$00       'f 102
     byte $00,$00,$6E,$33,$33,$3E,$30,$1F       'g 103
     byte $07,$06,$36,$6E,$66,$66,$67,$00       'h 104
     byte $0C,$00,$0E,$0C,$0C,$0C,$3F,$00       'i 105
     byte $30,$00,$38,$30,$30,$33,$33,$1E       'j 106
     byte $07,$66,$36,$1E,$16,$36,$67,$00       'k 107
     byte $0E,$0C,$0C,$0C,$0C,$0C,$3F,$00       'l 108
     byte $00,$00,$33,$7F,$7F,$6B,$63,$00       'm 109
     byte $00,$00,$1F,$33,$33,$33,$33,$00       'n 110
     byte $00,$00,$1E,$33,$33,$33,$1E,$00       'o 111
     byte $00,$00,$3B,$66,$66,$3E,$06,$0F       'p 112
     byte $00,$00,$6E,$33,$33,$3E,$30,$78       'q 113
     byte $00,$00,$3B,$6E,$66,$06,$0F,$00       'r 114
     byte $00,$00,$3E,$03,$1E,$30,$1F,$00       's 115
     byte $08,$0C,$3E,$0C,$0C,$2C,$18,$00       't 116
     byte $00,$00,$33,$33,$33,$33,$6E,$00       'u 117
     byte $00,$00,$33,$33,$33,$1E,$0C,$00       'v 118
     byte $00,$00,$63,$6B,$7F,$7F,$36,$00       'w 119
     byte $00,$00,$63,$36,$1C,$36,$63,$00       'x 120
     byte $00,$00,$33,$33,$33,$3E,$30,$1F       'y 121
     byte $00,$00,$3F,$19,$0C,$26,$3F,$00       'z 122






'{
' 0,1,1,1,1,1,0,0 124,198,206,222,246,230,204
' 1,1,0,0,0,1,1,0 198
' 1,1,0,0,1,1,1,0 206
' 1,1,0,1,1,1,1,0 222
' 1,1,1,1,0,1,1,0 246
' 1,1,1,0,0,1,1,0 230
' 0,1,1,1,1,1,0,0 124
' 0,0,0,0,0,0,0,0}
PUB plotPixel(xPixel, yPixel,pixelValue) '' 6 Stack Longs
                                                                 
'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Set a pixel on screen at the X Pixel and Y Pixel address to the pixel value of %%0, %%1, %%2, or %%3.                    │
'' │                                                                                                                          │
'' │ This function is very slow at drawing onscreen. It is here to show only how to do so.                                    │                                                                                
'' │                                                                                                                          │
'' │ PixelValue  - The new pixel value. %%0, %%1, %%2, or %%3.                                                                │
'' │ XPixel      - The X cartesian pixel coordinate.                                                                          │
'' │ YPixel      - The Y cartesian pixel coordinate. Note that this axis is inverted like on all other graphics drivers.      │ 
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  xPixel := ((xPixel <# constant(Horizontal_Resolution - 1)) #> 0)
  yPixel := ((constant(Horizontal_Resolution / 16) * ((yPixel <# constant(Vertical_Resolution - 1)) #> 0)) + (xPixel >> 4))
  xPixel := ((xPixel & $F) << 1)
  
  displayBuffer[yPixel] := ((displayBuffer[yPixel] & (!($3 << xPixel))) | (((pixelValue <# 3) #> 0) << xPixel))

pub plotchar(x,y,c,col)|b
    b := ((constant(Horizontal_Resolution / 16) * ((y <# constant(Vertical_Resolution - 1)) #> 0)) + (x >> 4))
    'b := x + (y * 320)
    x := ((x <# constant(Horizontal_Resolution - 1)) #> 0)
    x := ((x & $F) << 1)
    c:=((c-32)*8)' &= 255
    'c:=24
  repeat 8
    displayBuffer.byte[b] := font[c++] '|($3 << col)'^col'((col <# 3)#>0)

    b += 80
    'c ++'= 256

  'colour.byte[x + y * 40] := col{& $7F}
PUB clearDisplay(pixelPattern) '' 4 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Clears the whole display to the selected long pattern provided.                                                          │
'' │                                                                                                                          │
'' │ PixelPattern - The pixel pattern to clear the display to. 16 Pixels per long with values of %%0, %%1, %%2, or %%3.       │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  longfill(@displayBuffer, pixelPattern, Display_Buffer_size)

PUB displayPointer '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns the address of the display buffer.                                                                               │
'' │                                                                                                                          │
'' │ The display buffer is composed of an array of longs where every two bits represent one pixel.                            │
'' │                                                                                                                          │
'' │ There are four colors for the whole screen which map to the pixels values %%0, %%1, %%2, and %%3.                        │
'' │                                                                                                                          │
'' │ The LSBs of every long are the left most pixel while the MSBs of every long are the right most pixel.                    │
'' │                                                                                                                          │
'' │ Each long holds 16 pixels.                                                                                               │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘  

  return @displayBuffer

PUB displaySync '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns true while the driver is currently vertical refreshing and false if not.                                         │
'' │                                                                                                                          │
'' │ Use this function to look for the start of the vertical refresh to begin drawing on screen.                              │
'' │                                                                                                                          │ 
'' │ It is reconmended that you draw from top to bottom for the best picture quality without any flicker.                     │                                                                                            
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return syncIndicator

pub scroll
    longmove(@displayBuffer, @displayBuffer[160], 4640)
    longfill(@displayBuffer[4640], $0, 160)

PUB displayCount '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Returns a free running value that increments by one every vertical refresh cycle at 60 Hz.                               │
'' │                                                                                                                          │
'' │ Use this value to align graphics timings with the display refresh. Ex: Blinking stuff at 60Hz, 30Hz, 15Hz, etc.          │                                       
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  return displayAccumulator
  
PUB displayState(state) '' 4 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Enables or disables the bitmap driver's video output - turning the monitor off or putting it into standby mode.          │
'' │                                                                                                                          │
'' │ State - True for active and false for inactive.                                                                          │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  displayIndicator := not(state)

PUB changePixelColor(pixel, color) '' 5 Stack Longs 

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Changes the pixel color for the whole screen.                                                                            │
'' │                                                                                                                          │
'' │ Pixel  - Change this pixel value's color. %%0, %%1, %%2, or %%3.                                                         │                                                                                      
'' │ Colors - A color byte (%RR_GG_BB_xx) describing the pixel's new color.                                                   │ 
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  pixelColor.byte[((pixel <# 3) #> 0)] := color
  
PUB bitmapEngine '' 3 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Initializes the bitmap driver to run on a new cog.                                                                       │
'' │                                                                                                                          │
'' │ Returns the new cog's ID on sucess or -1 on failure.                                                                     │            
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  pixelColorAddress := @pixelColor

  syncIndicatorAddress := @syncIndicator 
  displayIndicatorAddress := @displayIndicator

  displayAAddress := @displayAccumulator

  frequencyState := ((constant((25_175_000 / 4) << 8) / clkfreq) << 24)
  
  return cognew(@initialization, @displayBuffer)

DAT

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Bitmap Driver
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        org                           

' //////////////////////Initialization/////////////////////////////////////////////////////////////////////////////////////////
                                                                                              
initialization          mov     vcfg,                 videoState                    ' Setup video hardware. 
                        mov     frqa,                 frequencyState                '
                        movi    ctra,                 #%0_00001_101                 '

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Active Video
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

loop                    mov     buffer,               par                           ' Set/Reset tiles fill counter.  
                        mov     tilesCounter,         #Vertical_Resolution          '                  

tilesDisplay            mov     tileCounter,          #Vertical_Scaling             ' Set/Reset tile fill counter.

tileDisplay             mov     vscl,                 visibleScale                  ' Set/Reset the video scale.
                        mov     counter,              #(Horizontal_Resolution / 16) '

' //////////////////////Visible Video//////////////////////////////////////////////////////////////////////////////////////////

videoLoop               rdlong  screenPixels,         buffer                        ' Download new pixels.
                        add     buffer,               #4                            '

                        waitvid screenColors,         screenPixels                  ' Update display scanline.
                                                                                 
                        djnz    counter,              #videoLoop                    ' Repeat.

' //////////////////////Invisible Video////////////////////////////////////////////////////////////////////////////////////////
                                                                                 
                        mov     vscl,                 invisibleScale                ' Set/Reset the video scale.
                                                                                 
                        waitvid HSyncColors,          syncPixels                    ' Horizontal Sync.

' //////////////////////Repeat/////////////////////////////////////////////////////////////////////////////////////////////////

                        sub     buffer,               #(Horizontal_Resolution / 4)  ' Repeat.
                        djnz    tileCounter,          #tileDisplay                  ' 

                        add     buffer,               #(Horizontal_Resolution / 4)  ' Repeat.
                        djnz    tilesCounter,         #tilesDisplay                 '

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Inactive Video
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        rdlong  screenColors,         pixelColorAddress             ' Get new screen colors.
                        or      screenColors,         HVSyncColors                  '

' //////////////////////Update Accumulator/////////////////////////////////////////////////////////////////////////////////////

                        rdword  buffer,               displayAAddress               ' Update display accumulator.
                        add     buffer,               #1                            '
                        wrword  buffer,               displayAAddress               '
                        
' //////////////////////Update Sync////////////////////////////////////////////////////////////////////////////////////////////

                        wrbyte  videoState,           syncIndicatorAddress          ' Update Sync Indicator to true.
                                                                                    ' Video state low byte is always $FF.                                                            

' //////////////////////Front Porch////////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              #11                           ' Set loop counter.
                                                                                 
frontPorch              mov     vscl,                 blankPixels                   ' Invisible lines.
                        waitvid HSyncColors,          #0                            '

                        mov     vscl,                 invisibleScale                ' Horizontal Sync.     
                        waitvid HSyncColors,          syncPixels                    '

                        djnz    counter,              #frontPorch                   ' Repeat # times.

' //////////////////////Vertical Sync//////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              #2                            ' Set loop counter.
                                                                                 
verticalSync            mov     vscl,                 blankPixels                   ' Invisible lines.
                        waitvid VSyncColors,          #0                            '     

                        mov     vscl,                 invisibleScale                ' Vertical Sync.     
                        waitvid VSyncColors,          syncPixels                    '

                        djnz    counter,              #verticalSync                 ' Repeat # times.

' //////////////////////Back Porch/////////////////////////////////////////////////////////////////////////////////////////////

                        mov     counter,              #31                           ' Set loop counter.    
                                                                                 
backPorch               mov     vscl,                 blankPixels                   ' Invisible lines.
                        waitvid HSyncColors,          #0                            '

                        mov     vscl,                 invisibleScale                ' Horizontal Sync.     
                        waitvid HSyncColors,          syncPixels                    '

                        djnz    counter,              #backPorch                    ' Repeat # times.

' //////////////////////Update Display Settings////////////////////////////////////////////////////////////////////////////////

                        rdbyte  buffer,               displayIndicatorAddress wz    ' Update display settings.  
                        muxz    dira,                 directionState                '

' //////////////////////Update Sync//////////////////////////////////////////////////////////////////////////////////////////// 

                        wrbyte  frequencyState,       syncIndicatorAddress          ' Update Sync Indicator to false. 
                                                                                    ' Frequency state low byte is always $00.
                        
' //////////////////////Loop///////////////////////////////////////////////////////////////////////////////////////////////////

                        jmp     #loop                                               ' Loop.

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'                       Data
' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

visibleScale            long    (Horizontal_Scaling << 12) + (10240 / Horizontal_Resolution) 
invisibleScale          long    (16 << 12) + 160                                    ' Invisible pixel scale for horizontal sync. 

blankPixels             long    640                                                 ' Blank scanline pixel length.                                                                                 
syncPixels              long    $00003FFC                                           ' Front porch, horizontal Sync, and back porch pixels.  
HSyncColors             long    $01030103                                           ' Horizontal sync color mask.
VSyncColors             long    $00020002                                           ' Vertical sync color mask.
HVSyncColors            long    $03030303                                           ' Horizontal and vertical sync colors.

' //////////////////////Configuration Settings/////////////////////////////////////////////////////////////////////////////////    

directionState          long    ($000000FF << (8 * ((Pin_Group <# 3) #> 0)))        ' Direction state configuration.
videoState              long    ($300000FF | (((Pin_Group <# 3) #> 0) << 9))        ' Video state configuration.
frequencyState          long    0                                                   ' Frequency state configuration.

' //////////////////////Addresses//////////////////////////////////////////////////////////////////////////////////////////////

pixelColorAddress       long    0

syncIndicatorAddress    long    0 
displayIndicatorAddress long    0

displayAAddress         long    0

' //////////////////////Run Time Variables/////////////////////////////////////////////////////////////////////////////////////

counter                 res     1                                      
buffer                  res     1

tileCounter             res     1
tilesCounter            res     1

screenPixels            res     1 
screenColors            res     1

' /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                        fit     496
                

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                        
