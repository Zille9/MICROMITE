{{      Mode2-VGA-Treiber Micromite für Hive
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Reinhard Zielinski                                                                            │
│ Copyright (c) 2014 Reinhard Zielinski                                                                │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : zille9@googlemail.com
System          : Hive
Name            : Mode8-VGA-Treiber 320x256 Pixel
Chip            : Bellatrix
Typ             : Treiber
Version         : 01
Subversion      : 00
Funktion        : VGA-Pixel-Text- und Tastatur-Treiber

Dieser Bellatrix-Code kann als Stadardcode im EEPROM gespeichert werden - Textbildschirm
und Tastaturfunktionen. Mit dem integrierten Loader kann Bellatrix
mit einem beliebigen anderen Code geladen werden.

Komponenten     : Mode8-VGA-Treiber für Micromite
                  PS/2 Keyboard Driver v1.0.1     Chip Gracey, ogg   MIT

COG's           : MANAGMENT     1 COG
                  VGA           1 COG
                  KEYB          1 COG
                  -------------------
                                3 COG's

Logbuch         :

25-01-2015       -Treibervariante2 von Kuroneko eingebunden, Auflösung entspricht dem KC85, Speicherverbrauch etwas geringer als in Variante 1
                 -Pixelausgabe recht einfach, Fontausgabegeschwindigkeit viel besser als im Modus 2 und 6
                 -Fontsatz entspricht im Aussehen sehr dem KC85 ->cool
                 -Farben setzen ist noch nicht ganz klar, aber wird schon
                 -3682 Longs frei

27-01-2015       -Farbzuweisung soweit erst mal ok
                 -Zuweisung erfolgt mit color vorder,hintergrund
                 -CLS-Routine geändert, damit der Bildschirm keine Streifenmuster anzeigt (war bei einigen Farbzuweisungen so)
                 -3685

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
DB_IN            = %00001001_00000000_00000000_00000000 'maske: dbus-eingabe
DB_OUT           = %00001001_00000000_00000000_11111111 'maske: dbus-ausgabe

M1               = %00000010_00000000_00000000_00000000
M2               = %00000010_10000000_00000000_00000000 'busclk=1? & /cs=0?

M3               = %00000000_00000000_00000000_00000000
M4               = %00000010_00000000_00000000_00000000 'busclk=0?

_pinGroup = 1
_startUpWait = 2

'' Terminal Vars
   CHAR_W	      = 80
   CHAR_H	      = 30

  Bel_Treiber_Ver=171                                                                                       'Bellatrix-Treiberversion Micromite-Mode2 Pixel-Treiber

CON
  res_x = vga#res_x
  res_y = vga#res_y

  quadP = res_x * res_y / 32
  quadC = res_x * res_y / 256

  flash = FALSE

  mbyte = $7F | flash & $80
  mlong = mbyte * $01010101

OBJ
     vga: "waitvid.320x256.driver.2048-1"
    font: "generic8x8-1font"
    keyb: "Keyboard"

VAR
  long	params[6]
  long  keycode                                                                                          'letzter tastencode
  long plen                                                                                              'länge datenblock loader
  long  sync
  word x_pos,y_pos

  byte proghdr[16]                                                                                       'puffer für objektkopf
  byte cursor

  long  link[vga#res_m], base

  long  screen[quadP]
  long  colour[quadC]
  long  vordergrund,hintergrund
  long screenfarbe
DAT

' Foreground colour is in byte 1, background in 3 and 0.

pb{ackground}   long    $0000 ->8, $0C0C ->8, $3030 ->8, $3C3C ->8
                long    $C0C0 ->8, $CCCC ->8, $F0F0 ->8, $FCFC ->8

pf{oreground}   long    $0000, $0800, $1000, $1800, $2000, $2800, $3000, $3800
                long    $8000, $8800, $9000, $9800, $A000, $A800, $B000, $B800

CON ''------------------------------------------------- BELLATRIX

PUB main | zeichen,a                             'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_subsysteme                                                                                        'bus/vga/keyboard/maus initialisieren

  repeat

    zeichen := bus_getchar                                                                               '1. zeichen empfangen
    if zeichen                                                                                           ' > 0

          chr(zeichen)
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
        12: CLS
        17: cursor:=bus_getchar                                                                          'Cursor On/Off
        20: vordergrund:=bus_getchar*8
            hintergrund:=bus_getchar+vordergrund
            setcolor

        31: locate(bus_getchar,bus_getchar)                                                              'Locate
        32: 'set(bus_getword,bus_getword)                                                                 'Set-xy
        34: Plot(bus_getword,bus_getword,bus_getchar)                                                    'Plot
        35: line(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar)                            'line
        36: box(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar)                             'box
        37: a:=bus_getchar                                                                               'scrolling
            repeat a
              scroll

'       ----------------------------------------------  CHIP-MANAGMENT
        96: mgr_getcogs                                                                                   'freie cogs abfragen
        87: mgr_load                                                                                      'neuen bellatrix-code laden
        98: mgr_bel                                                                                       'Rückgabe Grafiktreiber 64
        99: reboot                                                                                        'bellatrix neu starten


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
  outa[bus_hs] := 1
                                                                            'handshake inaktiv

  link{0} := @screen{0}
  link[1] := @colour{0}
  vga.init(-1, @link{0})                             ' start driver
  x_pos:=0
  y_pos:=0
  base := font.addr
  frqa := frqb := cnt
  link[2] := @pb{0}                                     ' |
  repeat while link[2]                                  ' update palette

  vordergrund:=104
  hintergrund:=105
  setcolor
  CLS

  keyb.start(keyb_dport)',keyb_cport)                                                                      'tastaturport starten
  waitcnt(clkfreq/10 + cnt)
  cursor:=1
  Show_cursor

pub setcolor
    screenfarbe:=0
            screenfarbe := hintergrund <<24                     '32 bit empfangen hsb/lsb
            screenfarbe := screenfarbe + vordergrund << 16
            screenfarbe := screenfarbe + vordergrund << 8
            screenfarbe := screenfarbe + hintergrund
            'printhex(screenfarbe,8)

PUB printhex(value, digits)                             'screen: hexadezimalen zahlenwert auf bildschirm ausgeben
{{hex(value,digits) - screen: hexadezimale bildschirmausgabe eines zahlenwertes}}
  value <<= (8 - digits) << 2
  repeat digits
    print(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

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
   outa[hbeat]~~
   waitpeq(M1,M2,0)                                     'busclk=1? & prop2=0?
   zeichen := ina[7..0]                                 'daten einlesen
   outa[bus_hs] := 0                                    'daten quittieren
   waitpeq(M3,M4,0)                                     'busclk=0?
   outa[bus_hs] := 1
   outa[hbeat]~
PUB bus_getword:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 32bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2][get.byte3][get.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

  wert := bus_getchar << 8
  wert := wert + bus_getchar
con'--------------------------------------------------- Mode8-Funktionen ---------------------------------------------------------------------------------------------------------
PUB chr(ch)|x,y,g

    case ch
        7:x_pos:=0             'Home
          y_pos:=0
        8:x_pos--            'Backspace
          if x_pos<1
             x_pos:=0
          if cursor
             print(160)
             print(32)
             x_pos--
          else
             print(32)
          if x_pos>0
             x_pos--
        9:Cursor_step
          settab(x_pos)         'Tab
        10:
        12:cls                  'CLS
        13:newline
        other:Cursor_step
              print(ch)   'Char



    if x_pos>39
       x_pos:=0
       y_pos++
    if y_pos>31
       scroll
    if x_pos<39
       Show_Cursor

pub settab(n)|v,ccol

    case n
         0..4:v:=4
         5..9:v:=9
         10..14:v:=14
         15..19:v:=19
         20..24:v:=24

    x_pos:=v

pub Show_Cursor|x
    if cursor
       print(160)
       x_pos--

pub locate(x,y)
    x_pos:=x
    y_pos:=y

pub newline
    cursor_step
    y_pos++             'Return
    x_pos:=0

pub cursor_step
    if cursor
       print(32)
       x_pos--

Pub plot(x,y,c)
    y:=y*10
    if c
       screen[y+x>>5]|= |<x
    else
       screen[y+x>>5]&= ! |<x

Pub CLS|a,b
    longfill(@screen, $0, 2560)
    colorfill
    x_pos:=0
    y_pos:=0

pub colorfill

    bytefill(@colour,screenfarbe,1280)

pub str(strg)
    repeat strsize(strg)
         chr(byte[strg++])

PUB line(x0, y0, x1, y1,n) | dX, dY, x, y, err, stp
  result := ((||(y1 - y0)) > (||(x1 - x0)))
  if(result)
    swap(@x0, @y0)
    swap(@x1, @y1)
  if(x0 > x1)
    swap(@x0, @x1)
    swap(@y0, @y1)
  dX := (x1 - x0)
  dY := (||(y1 - y0))
  err := (dX >> 1)
  stp := ((y0 => y1) | 1)
  y := y0
  repeat x from x0 to x1
    if(result)
      plot(y, x,n)
    else
      plot(x, y,n)
    err -= dY
    if(err < 0)
      y += stp
      err += dX

PRI swap(x, y)
  result  := long[x]
  long[x] := long[y]
  long[y] := result

PUB box(x0, y0, x1, y1,n) | i

    line(x0, y0, x1, y0,n)
    line(x0, y0, x0, y1,n)
    line(x0, y1, x1, y1,n)
    line(x1, y0, x1, y1,n)

PRI print(c) : b

  b := x_pos + y_pos * 320
  c &= 255

  repeat 8
    screen.byte[b] := byte[base][c]
    b += 40
    c += 256

  'colour.byte[x_pos + y_pos * 80]      := screenfarbe
  colour.byte[x_pos + y_pos * 40] := screenfarbe{& $7F}
  'colour.byte[x_pos + y_pos * 80 + 40] := screenfarbe'vordergrund | hintergrund<<8
  x_pos++

PRI scroll

  'repeat 64
    waitVBL
    longmove(@screen{0}, @screen[80], 2480)
    longfill(@screen[2480], 0, 80)
    longmove(@colour{0}, @colour[10], 310)
    bytefill(@colour[310], screenfarbe, 40)
    y_pos--
    x_pos:=0

PRI waitVBL : n

  n := link[3]
  repeat
  while n == link[3]

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
DINP    long  %00001001000000000000000000000000  'constant dinp hex  \ bus input
DOUT    long  %00001001000000000000000011111111  'constant dout hex  \ bus output

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
  sub_putword(keycode)

PUB key_spec                                                                                             'key: statustaten vom letzten tastencode abfragen

  bus_putchar(keycode >> 8)

DAT


                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops


DAT
     
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
