{{      Mode6-VGA-Treiber Micromite für Hive
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Reinhard Zielinski                                                                            │
│ Copyright (c) 2014 Reinhard Zielinski                                                                │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : zille9@googlemail.com
System          : Hive
Name            : Mode6-VGA-Treiber 320x240 Pixel 4Farben
Chip            : Bellatrix
Typ             : Treiber
Version         : 01
Subversion      : 00
Funktion        : VGA-Pixel-Text- und Tastatur-Treiber

Dieser Bellatrix-Code kann als Stadardcode im EEPROM gespeichert werden - Textbildschirm
und Tastaturfunktionen. Mit dem integrierten Loader kann Bellatrix
mit einem beliebigen anderen Code geladen werden.

Komponenten     : Mode6-VGA-Treiber für Micromite
                  PS/2 Keyboard Driver v1.0.1     Chip Gracey, ogg   MIT

COG's           :

Logbuch         :

22-01-2015      -Übernahme des Programmgerüstes vom Grafikmodus2, die meisten Funktionen können mit kleinen Änderungen übernommen werden
                -Funktionalität wie Modus2 realisiert
                -2379 Longs frei
25-01-2015      -KC85/2..4 Fontsatz übernommen, sieht wie echt aus :)
                -nun müsste die Zeichenausgabe noch schneller klappen, dann wäre es perfekt
                -2341 Longs frei

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

  Bel_Treiber_Ver=171                                                                                       'Bellatrix-Treiberversion Micromite-Mode2 Pixel-Treiber


OBJ
  vga        : "BMP4Engine"'
  keyb       : "keyboard"

VAR
  long	params[6]
  long  keycode                                                                                          'letzter tastencode
  long plen                                                                                              'länge datenblock loader
  'long  sync
  word x_pos,y_pos

  byte proghdr[16]                                                                                       'puffer für objektkopf
  byte cursor
CON ''------------------------------------------------- BELLATRIX

PUB main | zeichen,a,b,c                             'chip: kommandointerpreter
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
            if cursor
               Show_cursor
            else
               space(x_pos,y_pos)
        20: a:=bus_getchar                                                                     'Vorder-und Hintergrundfarbe
            b:=bus_getchar
            vga.changePixelColor(0,b)
            vga.changePixelColor(1,a)
            'vga.clearDisplay(0)
        31: locate(bus_getchar,bus_getchar)                                                              'Locate
        32: set(bus_getword,bus_getword)                                                                 'Set-xy
        34: vga.PlotPixel(bus_getword,bus_getword,bus_getchar)                                           'Plot x,y,farbe
        35: line(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar)                            'line
        36: box(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar)                             'box
        37: a:=bus_getchar
            b:=bus_getchar
            vga.changePixelColor(2,a)
            vga.changePixelColor(3,b)                                                                    'Farben 3 und 4

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
  outa[bus_hs] := 1                                                                                      'handshake inaktiv

  vga.BitmapEngine
  keyb.start(keyb_dport)',keyb_cport)                                                                      'tastaturport starten
  waitcnt(clkfreq/10 + cnt)

  vga.changePixelColor(0, $08) 'hintergrund
  vga.changePixelColor(1, $FF) 'vordergrund
  vga.changePixelColor(2, $80) 'vordergrund 2
  vga.changePixelColor(3, $F8) 'vordergrund 3
  cls


  cursor:=1

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
con'--------------------------------------------------- VGA-Funktionen -----------------------------------------------------------------------------------------------------------
PUB plotCharacter(character,col)| x,y,c,i,d'' 12 Stack Longs

'' ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
'' │ Draws a character on screen starting at the specified coordinace from the internal character rom.                        │
'' │                                                                                                                          │
'' │ This function is very slow at drawing onscreen. It is here to show only how to do so.                                    │
'' │                                                                                                                          │
'' │ Characters are ploted with %%0 pixels for their background and %%1 pixels for their foreground.                          │
'' │                                                                                                                          │
'' │ Character - The character to display on screen from the internal rom. There are 256 characters avialable.                │
'' │ XPixel    - The X cartesian pixel coordinate to start drawing at, will stop when drawing off screen, same for Y.         │
'' │ YPixel    - The Y cartesian pixel coordinate. Note that this axis is inverted like on all other graphics drivers.        │
'' │ XScaling  - Scales the character pixel image horizontally to increase the size of the character. Between 0 and 3.        │
'' │ YScaling  - Scales the character pixel image vertically to increase the size of the character. Between 0 and 3.          │
'' └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


  i:=(character-32)*8
  x:=x_pos
  y:=y_pos
  c:=font[i]

  repeat 8
       c:=font[i++]
       repeat 8
            if c & $80
                vga.plotPixel(x,y,col)
            c:=c<<1
            x++
       y++
       x:=x_pos
  x_pos+=8
  if x_pos>vga#Horizontal_Resolution-6
     newline


pub locate(y,x)
    x_pos:=x*8
    y_pos:=y*8

pub set(x,y)
    x_pos:=x
    y_pos:=y

pub getx

    sub_putword(x_pos)

pub gety

    sub_putword(y_pos)

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
      vga.plotpixel(y, x,n)
    else
      vga.plotpixel(x, y,n)
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

PUB chr(ch)|x,y,g

    case ch
        8:x_pos-=8            'Backspace
          if x_pos<1
             x_pos:=0
          if cursor
             space(x_pos+8,y_pos)
          space(x_pos,y_pos)
        9:Cursor_step
          settab(x_pos)         'Tab
        10:
        12:cls                  'CLS
        13:newline
        32:space(x_pos,y_pos)   'Space
           x_pos+=8
        33..127:Cursor_step
                plotCharacter(ch,1)   'Char

    if y_pos>vga#Vertical_Resolution-8
       scroll
    if x_pos<vga#Horizontal_Resolution-8
       Show_Cursor

pub newline
    cursor_step
    y_pos+=8             'Return
    x_pos:=0

pub cursor_step
    if cursor
       space(x_pos,y_pos)

pub Show_Cursor
    if cursor
       plotcharacter(126,1)
       x_pos-=8

pub space(x,y)|i
    repeat 8
        repeat i from x to x+8
                 vga.plotPixel(i,y,0)
        y++

pub settab(n)|v,ccol
    n/=8
    case n
         0..4:v:=4
         5..9:v:=9
         10..14:v:=14
         15..19:v:=19
         20..24:v:=24

    x_pos:=v*8

pub scroll
    vga.scroll
     y_pos-=8

pub cls|i,n
    vga.clearDisplay(0)
    x_pos:=0
    y_pos:=0

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




font            byte    0,0,0,0,0,0,0,0                 'Space
                byte    48,48,48,48,48,0,48,0           '!
                byte    119,51,102,0,0,0,0,0            '"
                byte    54,54,254,108,254,216,216,0     '#
                byte    24,62,108,62,27,27,126,24       '$
                byte    0,198,204,24,48,102,198,0       '%
                byte    56,108,56,118,220,204,118,0     '&
                byte    56,48,24,0,0,0,0,0              ''
                byte    24,48,96,96,96,48,24,0          '(
                byte    96,48,24,24,24,48,96,0          ')
                byte    0,102,60,255,60,102,0,0         '*
                byte    0,48,48,252,48,48,0,0           '+
                byte    0,0,0,0,0,28,12,24              ',
                byte    0,0,0,0,254,0,0,0               '-
                byte    0,0,0,0,0,48,48,0               '.
                byte    6,12,24,48,96,192,128,0         '/
                byte    124,198,206,222,246,230,124,0   '0
                byte    48,112,48,48,48,48,252,0        '1
                byte    120,204,12,56,96,204,252,0      '2
                byte    252,24,48,120,12,204,120,0      '3
                byte    28,60,108,204,254,12,30,0       '4
                byte    252,192,248,12,12,204,120,0     '5
                byte    56,96,192,248,204,204,120,0     '6
                byte    252,204,12,24,48,48,48,0        '7
                byte    120,204,204,120,204,204,120,0   '8
                byte    120,204,204,124,12,24,112,0     '9
                byte    0,0,48,48,0,48,48,0             ':
                byte    0,0,48,48,0,48,48,96            ';
                byte    24,48,96,192,96,48,24,0         '<
                byte    0,0,252,0,252,0,0,0             '=
                byte    96,48,24,12,24,48,96,0          '>
                byte    120,204,12,24,48,0,48,0         '?
                byte    28,12,24,0,0,0,0,0              ''
                byte    48,120,204,204,252,204,204,0    'A
                byte    252,102,102,124,102,102,252,0   'B
                byte    60,102,192,192,192,102,60,0     'C
                byte    248,108,102,102,102,108,248,0   'D
                byte    254,98,104,120,104,98,254,0     'E
                byte    254,98,104,120,104,96,240,0     'F
                byte    60,102,192,192,206,102,60,0     'G

                byte    204,204,204,252,204,204,204,0   'H
                byte    120,48,48,48,48,48,120,0        'I
                byte    30,12,12,12,204,204,120,0       'J
                byte    230,102,108,112,108,102,230,0   'K
                byte    240,96,96,96,98,102,254,0       'L
                byte    198,238,254,214,198,198,198,0   'M
                byte    198,230,246,222,206,198,198,0   'N
                byte    56,108,198,198,198,108,56,0     'O
                byte    252,102,102,124,96,96,240,0     'P
                byte    120,204,204,204,220,120,28,0    'Q
                byte    252,102,102,124,108,102,230,0   'R
                byte    124,198,240,60,14,198,124,0     'S
                byte    252,180,48,48,48,48,120,0       'T
                byte    204,204,204,204,204,204,120,0   'U
                byte    204,204,204,120,120,48,48,0     'V
                byte    198,198,198,214,254,238,198,0   'W
                byte    198,198,108,56,108,198,198,0    'X
                byte    204,204,204,120,48,48,120,0     'Y
                byte    254,198,140,24,50,102,254,0     'Z
                byte    120,96,96,96,96,96,120,0        '[
                byte    192,96,48,24,12,6,2,0           '\
                byte    240,48,48,48,48,48,240,0        ']
                byte    16,56,108,198,0,0,0,0           '^
                byte    0,0,0,0,0,0,0,255               '_
                byte    224,192,96,0,0,0,0,0            '`
                byte    0,0,120,12,124,204,118,0        'a
                byte    224,96,124,102,102,102,220,0    'b
                byte    0,0,120,204,192,204,120,0       'c
                byte    28,12,124,204,204,204,118,0     'd
                byte    0,0,120,204,252,192,120,0       'e
                byte    56,108,96,240,96,96,240,0       'f
                byte    0,0,118,204,204,124,12,248      'g
                byte    224,96,108,118,102,102,230,0    'h
                byte    48,0,112,48,48,48,252,0         'i
                byte    12,0,28,12,12,204,204,120       'j
                byte    224,96,102,108,120,108,230,0    'k
                byte    112,48,48,48,48,48,252,0        'l
                byte    0,0,204,254,254,214,198,0       'm
                byte    0,0,248,204,204,204,204,0       'n
                byte    0,0,120,204,204,204,120,0       'o
                byte    0,0,220,102,102,124,96,240      'p
                byte    0,0,118,204,204,124,12,30       'q
                byte    0,0,220,118,102,96,240,0        'r
                byte    0,0,124,192,120,12,248,0        's
                byte    16,48,124,48,48,52,24,0         't
                byte    0,0,204,204,204,204,118,0       'u
                byte    0,0,204,204,204,120,48,0        'v
                byte    0,0,198,214,254,254,108,0       'w
                byte    0,0,198,108,56,108,198,0        'x
                byte    0,0,204,204,204,124,12,248      'y
                byte    0,0,252,152,48,100,252,0        'z
                byte    24,48,48,96,48,48,24,0          '{
                byte    24,24,24,24,24,24,24,0          '|
                byte    24,12,12,6,12,12,24,0           '}
                byte    255,255,255,255,255,255,255,255 'Vollzeichen

                byte    170,170,170,170,170,170,170,170
                byte    255,0,255,0,255,0,255,0
                byte    170,85,170,85,170,85,170,85
                byte    204,204,51,51,204,204,51,51

                byte    14,12,12,204,108,60,28,0        '√
                byte    0,0,102,102,102,102,123,192     'µ
                byte    0,124,198,198,198,108,238,0     'Ω







'{
' 0,1,1,1,1,1,0,0 124,198,206,222,246,230,204
' 1,1,0,0,0,1,1,0 198
' 1,1,0,0,1,1,1,0 206
' 1,1,0,1,1,1,1,0 222
' 1,1,1,1,0,1,1,0 246
' 1,1,1,0,0,1,1,0 230
' 0,1,1,1,1,1,0,0 124
' 0,0,0,0,0,0,0,0

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
