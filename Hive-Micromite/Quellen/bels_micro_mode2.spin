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
Name            : Mode2-VGA-Treiber 512x384 Pixel
Chip            : Bellatrix
Typ             : Treiber
Version         : 01
Subversion      : 00
Funktion        : VGA-Pixel-Text- und Tastatur-Treiber

Dieser Bellatrix-Code kann als Stadardcode im EEPROM gespeichert werden - Textbildschirm
und Tastaturfunktionen. Mit dem integrierten Loader kann Bellatrix
mit einem beliebigen anderen Code geladen werden.

Komponenten     : Mode2-VGA-Treiber für Micromite
                  PS/2 Keyboard Driver v1.0.1     Chip Gracey, ogg   MIT

COG's           : MANAGMENT     1 COG
                  VGA           1 COG
                  KEYB          1 COG
                  -------------------
                                3 COG's

Logbuch         :

13-11-2014      :-erste Funktionen+Fontsatz
                 -428 Longs frei

03-01-2015       -Font-Verarbeitung geändert, dadurch viel Platz gespart, der Font besteht jetzt aus 7byte je Zeichen (6x7 Pixel 6breit, 7 hoch)
                 -988 Longs frei
15-01-2015       -Jetzt ist auch das Löschen von Bildschirmpunkten möglich
                 -Backspace-Funktion funktioniert jetzt richtig
                 -962 Longs frei
16-01-2015       -Cursor-Funktion hinzugefügt
                 -947 Longs frei
18-01-2015       -Scroll-Funktion hinzugefügt
                 -Locate-Funktion bestimmt die Textausgabeposition in x-Zeichen y-Zeichen (x=0-49 * y=0-47)
                 -937 Longs frei
25-01-2015       -KC85/2..4 Fontsatz übernommen, sieht wie echt aus :)
                 -nun müsste die Zeichenausgabe noch schneller klappen, dann wäre es perfekt
                 -886 Longs frei
30-01-2015       -Zeichenausgabe beschleunigt, allerdings kann der KC85 Fontsatz so nicht verwendet werden->muss gespiegelt werden :-(
                 -aushilfsweise Standard-8x8Fontsatz benutzt, der verbraucht aber mehr Speicher, da mehr Zeichen drin sind
                 -613 Longs frei
31-01-2015       -KC-Font erneut erstellt
                 -939 Longs frei
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
   CHAR_W	      = 80
   CHAR_H	      = 30

  Bel_Treiber_Ver=171                                                                                       'Bellatrix-Treiberversion Micromite-Mode2 Pixel-Treiber
  tiles    = vga#xtiles * vga#ytiles
  tiles32  = tiles * 32


OBJ
  vga        : "vga_pixel"'
  keyb       : "keyboard"
 ' font       : "small8x8-1font"
  fl         : "float32-Bas"'"fme"

VAR
  long	params[6]
  long  keycode                                                                                          'letzter tastencode
  long  plen, base                                                                                              'länge datenblock loader
  long  sync, pixels[tiles32]
  word  colors[tiles]
  long  x_pos,y_pos

  byte proghdr[16]                                                                                       'puffer für objektkopf
  byte vordergrund,hintergrund
  byte cursor,cback[8]
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
        20: vordergrund:=bus_getchar                                                                     'Vorder-und Hintergrundfarbe
            hintergrund:=bus_getchar
            wordfill(@colors,vordergrund << 8 | hintergrund,tiles)
        31: locate(bus_getchar,bus_getchar)                                                              'Locate
        32: a:=ptest(bus_getword,bus_getword)
            bus_putchar(a)                                                                               'PTest, testet, ob ein Pixel gesetzt ist
        34: Plot(bus_getword,bus_getword,bus_getchar)                                                    'Plot
        35: line(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar)                            'line
        36: box(bus_getword,bus_getword,bus_getword,bus_getword,bus_getchar)                             'box
        37: circle(sub_getword,sub_getword,sub_getword,sub_getword,bus_getchar)                          'Kreis

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
  'base := font.addr
  keyb.start(keyb_dport)',keyb_cport)                                                                      'tastaturport starten
  waitcnt(clkfreq/5 + cnt)

  vga.start(8, @colors, @pixels, @sync)

  vordergrund:=$FF
  hintergrund:=$08
  cls
  plot(0,0,1)
  waitcnt(clkfreq+cnt)
  fl.start

  cursor:=1
  bytefill(@cback,0,8)



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
PUB plot(x,y,s) | i

  if x => 0 and x < 512 and y => 0 and y < 384
    if s
       pixels[y << 4 + x >> 5] |= |< x                  'set
    else
       pixels[y << 4 + x >> 5]&= ! |< x                 'clear

pub ptest(x,y):c|t,yy
  if x => 0 and x < 512 and y => 0 and y < 384
     c:=(pixels[y << 4 + x >> 5] >> x)&1                  'get

pub locate(y,x)
    x_pos:=x'*8
    y_pos:=y'*8

{pub set(x,y)
    x_pos:=x
    y_pos:=y
}
{pub getx

    sub_putword(x_pos)

pub gety

    sub_putword(y_pos)
}
PUB circle(x,y,r,r2,set)|i,{xp,yp,}a,b,c,d,hd
    d:=630 '(2*pi*100)
    hd:=fl.ffloat(100)
    x:=fl.ffloat(x)
    y:=fl.ffloat(y)
    r:=fl.ffloat(r)
    r2:=fl.ffloat(r2)

    repeat i from 0 to d 'step 2
          c:=fl.fdiv(fl.ffloat(i),hd)
          a:=fl.fadd(x,fl.fmul(fl.cos(c),r))
          b:=fl.fadd(y,fl.fmul(fl.sin(c),r2))
          Plot(fl.FRound(a),fl.FRound(b),set)
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

PUB chr(ch)|x,y,g
    if cursor
       charbackup(0)                 'zeichen unter dem Cursor wiederherstellen
    case ch
        '2:x_pos --             'wird nicht benutzt
        '3:x_pos ++             'wird nicht benutzt
        '4:y_pos++              'wird nicht benutzt
        '5:y_pos--              'wird nicht benutzt
        7:x_pos:=0              'Home
          y_pos:=0
        8:x_pos--               'Backspace
          put(32,x_pos+1,y_pos)
        9:x_pos += (8 - (x_pos & $7))        'Tab
        10:
        12:cls                  'CLS
        13:y_pos++              'Return
           x_pos:=0
        other:print(ch)   'Char

    if x_pos<0
       x_pos:=63
       y_pos--
    if x_pos>63
       x_pos:=0
       y_pos++
    if y_pos>47
       scroll'(1)
    if y_pos<0
       y_pos:=0
    if cursor
       charbackup(1)
       put(96,x_pos,y_pos)

pub print(ch)|b
    b := (y_pos * 512)+x_pos
    ch:=(ch-32)*8

  repeat 8
    pixels.byte[b] :=font[ch++]

    b += 64
    'ch += 256
  x_pos++

pub charbackup(n)|i,b
    b := x_pos + (y_pos * 512)
    i:=0
  repeat 8
    if n
       cback[i++] := pixels.byte[b]                'backup
    else
       pixels.byte[b]:=cback[i++]                  'restore
    b += 64

pub put(c,x,y)|b
  b := x + (y * 512)
  c := (c-32)*8

  repeat 8
    pixels.byte[b] := font[c++]
    b += 64
    'c += 256

pub scroll

    longmove(@pixels,@pixels[128],6016)
    longfill(@pixels[6016], $0, 128)
    y_pos--

pri cls|i,n

    longfill(@pixels,$0,tiles32)
    wordfill(@colors,vordergrund << 8 | hintergrund,tiles)
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
  sub_putword(keycode)

PUB key_spec                                                                                             'key: statustaten vom letzten tastencode abfragen

  bus_putchar(keycode >> 8)

DAT


                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops

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

     byte $FF, $81, $81, $81, $81, $81, $81, $FF
     byte $FF, $81, $81, $81, $81, $81, $81, $FF





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
