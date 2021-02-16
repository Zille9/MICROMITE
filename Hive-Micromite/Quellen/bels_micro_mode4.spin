{{      Mode4-VGA-Sprite-Treiber Micromite für Hive
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Reinhard Zielinski                                                                            │
│ Copyright (c) 2014 Reinhard Zielinski                                                                │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : zille9@googlemail.com
System          : Hive
Name            : Mode4-Sprite-VGA-Treiber 256x256 Pixel
Chip            : Bellatrix
Typ             : Treiber
Version         : 01
Subversion      : 00
Funktion        :



Notizen:

}}


CON

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000

'signaldefinitionen bellatrixix

#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#8,     BEL_VGABASE                                     'vga-signale (8pin)
#16,    BEL_KEYBC,BEL_KEYBD                             'keyboard-signale
#18,    BEL_MOUSEC,BEL_MOUSED                           'maus-signale
#20,    BEL_VIDBASE                                     'video-signale(3pin)
#23,    BEL_SELECT                                      'belatrix-auswahlsignal
#24,    HBEAT                                           'front-led
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal
#41,    RTC_GETSECONDS                              'Returns the current second (0 - 59) from the real time clock.
        RTC_GETMINUTES                              'Returns the current minute (0 - 59) from the real time clock.
        RTC_GETHOURS                                'Returns the current hour (0 - 23) from the real time clock.
'                   +----------
'                   |  +------- system     
'                   |  |  +---- version    (änderungen)
'                   |  |  |  +- subversion (hinzufügungen)
'CHIP_VER        = $00_01_02_01
'
'                                           +---------- 
'                                           | +-------- 
'                                           | |+------- vektor
'                                           | ||+------ grafik
'                                           | |||+----- text
'                                           | ||||+---- maus
'                                           | |||||+--- tastatur
'                                           | ||||||+-- vga
'                                           | |||||||+- tv
CHIP_SPEC       = %00000000_00000000_00000000_00010110


KEYB_DPORT   = BEL_KEYBD                               'tastatur datenport
KEYB_CPORT   = BEL_KEYBC                               'tastatur taktport
mouse_dport  = BEL_MOUSED
mouse_cport  = BEL_MOUSEC

'          hbeat   --------+                            
'          clk     -------+|                            
'          /wr     ------+||                            
'          /hs     -----+||| +------------------------- /cs
'                       |||| |                 -------- d0..d7
DB_IN            = %00001000_00000000_00000000_00000000 'maske: dbus-eingabe
DB_OUT           = %00001000_00000000_00000000_11111111 'maske: dbus-ausgabe

M1               = %00000010_00000000_00000000_00000000
M2               = %00000010_10000000_00000000_00000000 'busclk=1? & /cs=0?

M3               = %00000000_00000000_00000000_00000000
M4               = %00000010_00000000_00000000_00000000 'busclk=0?

_pinGroup = 1
_startUpWait = 2

'' Terminal Vars
   CHAR_W             = 80
   CHAR_H             = 30

  Bel_Treiber_Ver=173                                                                                      'Bellatrix-Treiberversion Micromite-Mode4 Sprite-Tile-Treiber

        '' Sprite & Tiles Settings
        TILENUM       = 64
        SPRITENUM     = 16
        TILESIZE      = 8 * 8      '' Define Tile/Character Size.
        SPRITESIZE    = 16 * 16    '' Define Sprite Size

        '' Sprite Attribute enumeration
        StartFrame    = 0
        EndFrame      = 1
        CurrentFrame  = 2
        FrameDelay    = 3
        Xpos          = 4
        Ypos          = 5
        XDelay        = 6
        YDelay        = 7
        XInc          = 8
        YInc          = 9
        'Future Use1   = 10 - 15

        SprPalette    = 0
        TilPalette    = 6

        Keyboard      = 2
        ColorMode     = 0

OBJ
        driver  : "vga_driver"'_256c"
        render  : "graphics_renderer"
        keyb    : "keyboard"
        nlib    : "numbers"
        data    : "demo_graphics"
VAR
  long  params[6]

  long  keycode                                                                                          'letzter tastencode

  long plen col, row,flag ,out_ptr ,color                                                                                           'länge datenblock loader
  long bg_ptr, bg_col, bg_x
  byte proghdr[16]                                                                                       'puffer für objektkopf
  byte strkette[40]                                                                                      'stringpuffer fuer Scrolltext

  ' Sprite status
  byte objects
  byte tick[render#MAX_SPRITES]
  byte increment[render#MAX_SPRITES]
  byte sprite[render#MAX_SPRITES]
  byte position_x[render#MAX_SPRITES]
  byte position_y[render#MAX_SPRITES]
  byte mirror[render#MAX_SPRITES]
  long frame_buffer[64]
  long frame_indicator
  long mapdata

     '' Local locations for eight sprites
   byte sprite1x
   byte sprite1y
   byte sprite2x
   byte sprite2y
   byte sprite3x
   byte sprite3y
   byte sprite4x
   byte sprite4y
   byte sprite5x
   byte sprite5y
   byte sprite6x
   byte sprite6y
   byte sprite7x
   byte sprite7y
   byte sprite8x
   byte sprite8y

   byte Juggler
   byte GraphicsMode

CON ''------------------------------------------------- BELLATRIX

PUB main | zeichen,n,i,x,y ,o,c ,a,b,frame                          'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_subsysteme                                                                                        'bus/vga/keyboard/maus initialisieren
  n:=0
  frame:=-1

  repeat
    {frame++

       repeat i from 0 to 15

         o:=@SprAttr+i<<4
         if frame // byte[o][Framedelay] == 0
           c:=byte[o][CurrentFrame]
           if c == byte[o][EndFrame]
             c:= byte[o][StartFrame]
           else
             c+=1
           byte[o][CurrentFrame]:=c

           render.sprite_image(i,c)


         if frame // byte[o][xdelay] == 0
             byte[o][xpos] += byte[o][xinc]

         if frame // byte[o][ydelay] == 0
             byte[o][ypos] += byte[o][yinc]

         render.sprite_move(i,byte[o][xpos],byte[o][ypos])
    }
    driver.wait_vbl

    render.set_background_origin(bg_x, 0)
    render.flip
    'scroll_background_right
    'if ina[23]
       zeichen := bus_getchar                                                                               '1. zeichen empfangen
       if zeichen                                                                                           ' > 0
          print(zeichen)

       else
         zeichen := bus_getchar                                                                             '2. zeichen kommando empfangen
         case zeichen
          1: key_stat                                                                                      '1: Tastaturstatus senden
          2: key_code                                                                                      '2: Tastaturzeichen senden
          3:
          4: key_spec                                                                                      '4: Statustasten ($100..$1FF) abfragen
          5:
          6:
          7:
          8:
          9:
          10:
          11:
          12:
          20:sprite_palette(bus_getchar,bus_getchar)
          21:Longsprite(sub_getlong,sub_getlong)
          22:Longtiles(sub_getlong,sub_getlong)
          23:render.set_background_origin(bus_getchar,bus_getchar)
          24:write_byte_at(bus_getchar,bus_getchar,bus_getchar,bus_getchar)
          25:resetallsprites
          26:Animate(bus_getchar,bus_getchar,bus_getchar,bus_getchar)
          27:MoveSpeed(bus_getchar,bus_getchar,bus_getchar,bus_getchar,bus_getchar)
          28:SetSprPos(bus_getchar,bus_getchar,bus_getchar)
          29:PaletteColorDef(bus_getchar,bus_getchar,bus_getchar)
          30:LoadSpr(bus_getchar,bus_getchar,bus_getchar,bus_getchar,bus_getchar,bus_getchar)
          31:render.sprite_hide(bus_getchar)
          33:render.sprite_move(bus_getchar,bus_getchar,bus_getchar)
          34:a:=bus_getchar
             bus_putchar(@SprAttr+a<<4)
          35:a:=bus_getchar
             b:=bus_getchar
            'render.sprite_image(a,b)
'        ----------------------------------------------  CHIP-MANAGMENT
          96: mgr_getcogs                                                                                   'freie cogs abfragen
          87: mgr_load                                                                                      'neuen bellatrix-code laden
          98: mgr_bel                                                                                       'Rückgabe Grafiktreiber 64
          99: reboot                                                                                        'bellatrix neu starten

pub sprite_palette(a,b)
    byte[@Palettes][SprPalette<<4+a]:=b

pub Longsprite(a,b)
    long[@sprites][a] :=b

pub Longtiles(a,b)
    long[@tiles][a] := b

pub LoadSpr(si,st,sx,sy,mr,sp)
    render.sprite_show(si,st,sp,sx,sy,0,mr)
    SetSprPos(si,sx,sy)
    Animate(si, st, st, 100)

PRI write_byte_at(x,y,palette,text) | pos, i,c

 '######## nach bella #######
  palette <<= 8

  pos := y * render#ROW_SIZE_WORD + x
    c := text
    case c
      $00..$20: c := c - 32
      $30..$39: c := c - 47 'numbers 0-9
      $41..$5A: c := c - 54 'uppercase A-Z
      $61..$7A: c := c - 59 '86 'lowercase a-z (Tile 39/a - 62/z
      $7B..$FF: '
      "-": c := 37
      other: c := 0
    word[@map_def][pos++] := palette | c
PUB str(stringptr)

  repeat strsize(stringptr)
    out(byte[stringptr++])

PUB out(c)

  case flag
    $00: case c
           $00: longfill(render.get_tilemap_address(0, 0), 0, render#MAP_SIZE_LONG)
                col := row := 0
                out_ptr := render.get_tilemap_address(0, 0)
           $01: col := row := 0
                out_ptr := render.get_tilemap_address(0, 0)
           $02: longfill(render.get_tilemap_address(0, row), 0, render#ROW_SIZE_LONG)
           $08: if col
                  col--
                  out_ptr -= 2
           $09: repeat
                  print(" ")
                while col & 7
           $0A..$0C: flag := c
                     return
           $0D: newline
           other: print(c)
    $0A: col := c // 32
         out_ptr := render.get_tilemap_address(col, row)
    $0B: row := c // 32
         out_ptr := render.get_tilemap_address(col, row)
    $0C: color := c
  flag := 0

PRI print(c)

  case c
    $30..$39: c := c - $30 + data#FONT_0
    $41..$5A: c := c - $41 + data#FONT_A
    $61..$7A: c := c - $61 + data#FONT_A
    "-": c := data#FONT_MINUS
    other: c := data#FONT_SPACE

  word[out_ptr] := (color << 8) | c
  out_ptr += 2
  if ++col == render#H_TILES
    newline

PRI newline

  col := 0
  row++
  out_ptr := row * render#H_TILES

PUB draw_str(stringptr)

  repeat strsize(stringptr)
    draw_print(byte[stringptr++])

PRI draw_print(c) | dptr,sptr

  dptr := data.get_sprite_def + 128 * (col / 2)
  dptr += 64 * row
  dptr += 4 * (col // 2)

  case c
    $30..$39: c := c - $30 + data#FONT_0
    $41..$5A: c := c - $41 + data#FONT_A
    $61..$7A: c := c - $61 + data#FONT_A
    "-": c := data#FONT_MINUS
    other: c := data#FONT_SPACE

  sptr := data.get_tile_def + c * 32

  repeat 8
    long[dptr] := long[sptr]
    dptr += 8
    sptr += 4

  col++

PUB init_background | ptr

  bg_ptr := data.get_map_def

  repeat bg_col from 0 to 32
    ptr := render.get_tilemap_address(bg_col, 23)
    repeat data#MAP_DEF_HEIGHT
      word[ptr] := word[bg_ptr]
      ptr -= render#H_TILES * 2
      bg_ptr += 2

  bg_x := 0

PUB scroll_background_right | ptr

  if ++bg_x == 8
    ptr := render.get_tilemap_address(0, 23)
    repeat data#MAP_DEF_HEIGHT
      wordmove(ptr, ptr + 2, render#H_TILES - 1)
      ptr -= render#H_TILES * 2

    if ++bg_col == data#MAP_DEF_WIDTH
      bg_col := 0
      bg_ptr := data.get_map_def

    ptr := render.get_tilemap_address(32, 23)
    repeat data#MAP_DEF_HEIGHT
      word[ptr] := word[bg_ptr]
      ptr -= render#H_TILES * 2
      bg_ptr += 2

    bg_x := 0
PUB scroll_background_left | ptr

  if --bg_x == 8
    ptr := render.get_tilemap_address(0, 23)
    repeat data#MAP_DEF_HEIGHT
      wordmove(ptr, ptr - 2, render#H_TILES - 1)
      ptr += render#H_TILES * 2

    if --bg_col == data#MAP_DEF_WIDTH
      bg_col := data#MAP_DEF_WIDTH
      bg_ptr := data.get_map_def

    ptr := render.get_tilemap_address(32, 23)
    repeat data#MAP_DEF_HEIGHT
      word[ptr] := word[bg_ptr]
      ptr += render#H_TILES * 2
      bg_ptr -= 2

    bg_x := 0
pub resetallsprites

  sprite1x:=0
  sprite1y:=0
  sprite2x:=0
  sprite2y:=0
  sprite3x:=0
  sprite3y:=0
  sprite4x:=0
  sprite4y:=0
  sprite5x:=0
  sprite5y:=0
  sprite6x:=0
  sprite6y:=0
  sprite7x:=0
  sprite7y:=0
  sprite8x:=0
  sprite8y:=0

pub Animate(spri, startfrm, endfrm, dly) | o
        o:=@SprAttr+spri<<4
        byte[o][Framedelay] := dly
        byte[o][CurrentFrame] := startfrm
        byte[o][StartFrame] := startfrm
        byte[o][EndFrame] := endfrm

pub MoveSpeed(spri, xdly, ydly, xi, yi) | o
        o:=@SprAttr+spri<<4
        byte[o][xdelay] := xdly
        byte[o][ydelay] := ydly
        byte[o][xinc] := xi
        byte[o][yinc] := yi
        'sprmove[spri]:=1 '' Assume this sprite will move

pub SetSprPos(spri, xp, yp) | o
        o:=@SprAttr+spri<<4
        byte[o][xpos] := xp
        byte[o][ypos] := yp

pub PaletteColorDef(num,idx,colr)
    byte[@Palettes+num<<4][idx] := colr

PUB init_subsysteme|i',x,y,tn,tmp                                   'chip: initialisierung des bellatrix-chips
''funktionsgruppe               : chip
''funktion                      : - initialisierung des businterface
''                              : - vga & keyboard-treiber starten
''eingabe                       : -
''ausgabe                       : -
  repeat i from 0 to 7                                                                                   'evtl. noch laufende cogs stoppen
      ifnot i == cogid
            cogstop(i)


  dira := db_in                                                                                          'datenbus auf eingabe schalten
  outa[bus_hs] := 1                                                                                      'handshake inaktiv
  GraphicsMode := 1

  Juggler:=Keyboard
  keyb.start(keyb_dport)',keyb_cport)                                                                      'tastaturport starten
  waitcnt(clkfreq/10 + cnt)

  driver.start(@frame_buffer, @frame_indicator, render#vres)

  render.start(@frame_buffer, @frame_indicator, @map1, data.get_tile_def, data.get_palette_def, data.get_sprite_def)
  render.start_doublebuffer(@map2)
  render.set_locked_lines(104)

  str(string($A, 1, $B, 1, "PROPELLER"))
  'wordfill(render.get_tilemap_address(0, 12), data#SKY, 12 * render#H_TILES)

  init_background

PUB bus_putchar(zeichen)                                'chip: ein byte an regnatix senden
''funktionsgruppe               : chip
''funktion                      : ein byte an regnatix senden
''eingabe                       : byte
''ausgabe                       : -

  waitpeq(M1,M2,0)                                      'busclk=1? & prop2=0?
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa[7..0] := zeichen                                 'daten ausgeben
  outa[bus_hs] := 0                                     'daten gültig
  waitpeq(M3,M4,0)                                      'busclk=0?
  dira := db_in                                         'bus freigeben
  outa[bus_hs] := 1                                     'daten ungültig

PUB bus_getchar : zeichen                               'chip: ein byte von regnatix empfangen
''funktionsgruppe               : chip
''funktion                      : ein byte von regnatix empfangen
''eingabe                       : -
''ausgabe                       : byte
   'outa[hbeat]~~
   waitpeq(M1,M2,0)                                     'busclk=1? & prop2=0?
   zeichen := ina[7..0]                                 'daten einlesen
   outa[bus_hs] := 0                                    'daten quittieren
   waitpeq(M3,M4,0)                                     'busclk=0?
   outa[bus_hs] := 1
   'outa[hbeat]~
PUB bus_getword:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert := bus_getchar << 8
  wert := wert + bus_getchar
con'--------------------------------------------------- VGA-Funktionen -----------------------------------------------------------------------------------------------------------


CON ''------------------------------------------------- SUBPROTOKOLL-FUNKTIONEN

PUB sub_putlong(wert)                                   'sub: long senden       
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   bus_putchar(wert >> 24)                              '32bit wert senden hsb/lsb
   bus_putchar(wert >> 16)
   bus_putchar(wert >> 8)
   bus_putchar(wert)

PUB sub_getlong:wert                                    'sub: long empfangen    
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert :=        bus_getchar << 24                      '32 bit empfangen hsb/lsb
  wert := wert + bus_getchar << 16
  wert := wert + bus_getchar << 8
  wert := wert + bus_getchar
PUB sub_putword(wert)                                   'sub: long senden
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   bus_putchar(wert >> 8)
   bus_putchar(wert)

PUB sub_getword:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert := bus_getchar << 8
  wert := wert + bus_getchar

CON ''------------------------------------------------- CHIP-MANAGMENT-FUNKTIONEN

pub mgr_bel
    sub_putlong(Bel_Treiber_Ver)                                                                         'rückgabe 65 für tile-driver 64 farben stark geänderte Version

PUB mgr_getcogs: cogs |i,c,cog[8]                                                                        'cmgr: abfragen wie viele cogs in benutzung sind
''funktionsgruppe               : cmgr
''funktion                      : abfrage wie viele cogs in benutzung sind
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [0][096][put.cogs]
''                              : cogs - anzahl der belegten cogs

  cogs := i := 0
  repeat                                                                                                 'loads as many cogs as possible and stores their cog numbers
    c := cog[i] := cognew(@entry, 0)
    if c=>0
      i++
  while c => 0
  cogs := i
  repeat                                                                                                 'unloads the cogs and updates the string
    i--
    if i=>0
      cogstop(cog[i])
  while i=>0
  bus_putchar(cogs)

PUB mgr_load|i                                          'cmgr: bellatrix-loader
''funktionsgruppe               : cmgr
''funktion                      : funktion um einen neuen code in bellatrix zu laden
''
''bekanntes problem: einige wenige bel-dateien werden geladen aber nicht korrekt gestartet
''lösung: diese datei als eeprom-image speichern

' kopf der bin-datei einlesen                           ------------------------------------------------------
  repeat i from 0 to 15                                                                                  '16 bytes --> proghdr
    byte[@proghdr][i] := bus_getchar

  plen := 0
  plen :=        byte[@proghdr + $0B] << 8
  plen := plen + byte[@proghdr + $0A]
  plen := plen - 8

' objektlänge an regnatix senden
  bus_putchar(plen >> 8)                                                                                 'hsb senden
  bus_putchar(plen & $FF)                                                                                'lsb senden

  repeat i from 0 to 7                                                                                   'alle anderen cogs anhalten
    ifnot i == cogid
      cogstop(i)

  dira := 0                                                                                              'diese cog vom bus trennen
  cognew(@loader, plen)

  cogstop(cogid)                                                                                         'cog 0 anhalten

DAT
                        org     0

loader
                        mov     outa,    M_0               'bus inaktiv
                        mov     dira,    DINP              'bus auf eingabe schalten
                        mov     reg_a,   PAR               'parameter = plen
                        mov     reg_b,   #0                'adresse ab 0

                        ' datenblock empfangen
loop
                        call    #get                       'wert einlesen
                        wrbyte  in,      reg_b             'wert --> hubram
                        add     reg_b,   #1                'adresse + 1
                        djnz    reg_a,   #loop

                        ' neuen code starten

                        rdword  reg_a,   #$A               ' Setup the stack markers.
                        sub     reg_a,   #4                '
                        wrlong  SMARK,   reg_a             '
                        sub     reg_a,   #4                '
                        wrlong  SMARK,   reg_a             '

                        rdbyte  reg_a,   #$4               ' Switch to new clock mode.
                        clkset  reg_a                                             '

                        coginit SINT                       ' Restart running new code.


                        cogid   reg_a
                        cogstop reg_a                      'cog hält sich selbst an


get
                        waitpeq M_1,      M_2              'busclk=1? & /cs=0?
                        mov     in,       ina              'daten einlesen
                        and     in,       DMASK            'wert maskieren
                        mov     outa,     M_3              'hs=0
                        waitpeq M_3,      M_4              'busclk=0?
                        mov     outa,     M_0              'hs=1
get_ret                 ret


'     hbeat   --------+
'     clk     -------+|
'     /wr     ------+||
'     /hs     -----+|||+------------------------- /cs
'                  |||||                 -------- d0..d7
DINP    long  %00001000000000000000000000000000  'constant dinp hex  \ bus input
DOUT    long  %00001000000000000000000011111111  'constant dout hex  \ bus output

M_0     long  %00001000000000000000000000000000  'bus inaktiv

M_1     long  %00000010000000000000000000000000
M_2     long  %00000010100000000000000000000000  'busclk=1? & /cs=0?

M_3     long  %00000000000000000000000000000000
M_4     long  %00000010000000000000000000000000  'busclk=0?


DMASK   long  %00000000000000000000000011111111  'datenmaske

SINT    long    ($0001 << 18) | ($3C01 << 4)                       ' Spin interpreter boot information.
SMARK   long    $FFF9FFFF                                          ' Stack mark used for spin code.

in      res   1
reg_a   res   1
reg_b   res   1



CON ''------------------------------------------------- KEYBOARD-FUNKTIONEN

PUB key_stat                                                                                             'key: tastaturstatus abfragen

  bus_putchar(keyb.gotkey)

PUB key_code                                                                                             'key: tastencode abfragen

  keycode := keyb.key
  'case keycode
  '  $c8: keycode := $08                                                                                  'backspace wandeln
  sub_putword(keycode)

PUB key_spec                                                                                             'key: statustaten vom letzten tastencode abfragen

  bus_putchar(keycode >> 8)

DAT


                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops

command         long    0

DAT

map_def         word    $00_00 [render#MAP_SIZE_WORD]


SprAttr
'                        ---------------------------------- StartFrame    = 0
'                        |   ------------------------------ EndFrame      = 1
'                        |  |  ---------------------------- CurrentFrame  = 2
'                        |  |  |  ------------------------- FrameDelay    = 3
'                        |  |  |  |
'                        |  |  |  |
'                        |  |  |  |
'                        |  |  |  |
'                        |  |  |  |
'              byte      0, 0, 0, 0, 0, 0, 0, 0

              byte    0[16*16]
Palettes
        ''0
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

        ''1
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

        ''2
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

        ''3
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

        ''4
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

        ''5
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

        ''6       ''
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

        ''7       ''
        byte    $00,$08,$80,$88
        byte    $20,$28,$A0,$A8
        byte    $54,$0C,$C0,$CC
        byte    $30,$3C,$F0,$FC

sprites byte 0 [SPRITENUM * SPRITESIZE+1] ' Define space for 16 sprites
tiles   byte 0 [TILENUM * TILESIZE+1]       'Define space for 64 tiles.
DAT
map1            word    0 [render#MAP_SIZE_WORD]
map2            word    0 [render#MAP_SIZE_WORD]

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
