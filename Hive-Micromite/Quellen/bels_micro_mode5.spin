CON

  _clkmode = xtal1+pll16x
  _clkfreq = 80_000_000 '-00_000_010

'********************************************************************************************
' Nostalgic VGA - 2 cogs version
' Version 0.34 beta - 16.06.2012
' 2 cogs, 80..120 Mhz
' 80x30 text with border, 8x16 font
' (c) 2012 Piotr Kardasz pik33@o2.pl
' MIT license: see end of file
'********************************************************************************************

'********************************************************************************************
'VGA pins setting, 0 - 0..7; 1 - 8..15, 2 - 16..23, 3 - 24..31

 _vgapins = 1

'********************************************************************************************
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

  Bel_Treiber_Ver=174                                                                                      'Bellatrix-Treiberversion Micromite-Mode5 Nostalgic-Treiber

var
byte buf[2400]
byte line_buf[840] ' 4 lines 2 line buffers
long cursor_buf[4] ' cursor shape
byte n_string[12]  ' string buffer for inttostr and hextostr
byte chardef[16]   'buffer for char redefine function


long buf_ptr
long font_ptr
long line_buf_ptr
long cursor_buf_ptr
long cmd1
long cmd2
long cursor
'long cursor_blink_rate
long vblank

long params[6]

long keycode                                                                                          'letzter tastencode

long plen                                                                                              'länge datenblock loader
byte proghdr[16]                                                                                       'puffer für objektkopf
byte strkette[40]                                                                                      'stringpuffer fuer Scrolltext
byte cursor_onoff

obj  keyb        :"Keyboard"
CON ''------------------------------------------------- BELLATRIX

PUB main | zeichen,n,i,x,y ,speed                             'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_subsysteme                                                                                        'bus/vga/keyboard/maus initialisieren
  n:=0

  repeat

    zeichen := bus_getchar                                                                               '1. zeichen empfangen
    if zeichen                                                                                           ' > 0
          pchar(zeichen)
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
        12:  cls
        17: cursor_onoff:=bus_getchar
            x:=cursor&255
            y:=(cursor>>8)&255
            if cursor_onoff
               putchar(x,y,95)
            else
               putchar(x,y,32)

        20:  'setcolors(bus_getchar,bus_getchar)
        200: 'redefine
        201: 'vga.Plot(bus_getchar,bus_getchar,bus_getchar)
        202: 'line(bus_getchar,bus_getchar,bus_getchar,bus_getchar,bus_getchar)
        203: 'box(bus_getchar,bus_getchar,bus_getchar,bus_getchar,bus_getchar)
        209: 'vga.addsprite(bus_getchar)
        210: 'setsprite(bus_getchar,bus_getchar,bus_getchar)
        211: 'bus_putchar(vga.peek(bus_getchar,bus_getchar))

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

  start
  cls

  '#### c64 Optik #############
  setscreencolors (2,2,3,1,1,2)
  setbordcolors (2,2,3)
  '############################

  keyb.start(keyb_dport)',keyb_cport)                                                                      'tastaturport starten
  waitcnt(clkfreq/10 + cnt)


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



{{pub demo | random, i, j, s1,s2,s3,s4,s5,s6,s7,s8,x1,y1

s1:=string("VGA Nostalgic 80x30 text with border driver demo")
s2:=string("It uses Atari ST mono 8x16 font")
s3:=string("Every 4-letter group can have its own foreground and background color")
s4:=string("Every line can have its own border color")
s5:=string("No hub RAM used for color buffer")
s6:=string("You can set colors for all screen using one function call")
s7:=string("You can set border color for all screen using one function call, too")
's8:=string("1234567890")
start
j:=0

repeat


  cls

  setscreencolors (2,5,6,0,8,1)
  setbordcolors (1,5,0)
  cursoroff

  outtextxy (40-(strsize(s1)>>1),10,s1)
  waitcnt(cnt+clkfreq)

  repeat i from 4 to 15
    setfontcolor (12,i,3,5,0)

  outtextxy (40-(strsize(s2)>>1),12,s2)
  waitcnt(cnt+clkfreq<<2)

  setscreencolors (3,2,2,5,0,1)

  j:=3
  repeat i from 0 to 2399
    if (j>127)
      j:=2
    buf[i]:=j
    j:=j+1

  waitcnt(cnt+clkfreq<<2)

  waitcnt(cnt+clkfreq<<2)
  waitcnt(cnt+clkfreq<<2)

  waitcnt(cnt+clkfreq<<2)
  repeat j from 0 to 29
    scrolldown

  outtextxy (40-(strsize(s3)>>1),10,s3)
  waitcnt(cnt+clkfreq)
  outtextxy (40-(strsize(s4)>>1),12,s4)
  waitcnt(cnt+clkfreq)
  outtextxy (40-(strsize(s5)>>1),14,s5)
  waitcnt(cnt+clkfreq<<3)


  waitcnt (cnt+clkfreq<<2)

  j:=3
  repeat i from 0 to 2399
    if (j>127)
      j:=2
    buf[i]:=j
    j:=j+1

  repeat i from 0 to 29
    setbordcolor(i,random? & 3,random? & 3,random? & 3)
    repeat j from 0 to 19
      setfontcolor(i,j,random? & 3,random? & 3,random? & 3)
      setbackcolor(i,j,random? & 3,random? & 3,random? & 3)

  waitcnt (cnt+_clkfreq<<2)


  cls
  setscreencolors (3,2,2,0,0,1)
  setbordcolors(0,0,1)

  outtextxy (40-(strsize(s6)>>1),10,s6)
  waitcnt(cnt+clkfreq)


  random:=cnt

  repeat j from 0 to 15

    waitcnt (cnt+_clkfreq>>1)
    setscreencolors (random? & 3,random? & 3,random? & 3,random? & 3,random? & 3,random? & 3)

  setscreencolors (3,2,2,0,0,1)

  outtextxy (40-(strsize(s7)>>1),12,s7)
  waitcnt(cnt+clkfreq)

  repeat j from 0 to 15
    waitcnt (cnt+clkfreq>>1)
    setbordcolors (random? & 3,random? & 3,random? & 3)

  waitcnt (cnt+clkfreq>>1)
  setbordcolors(0,0,1)

  cursoron

  repeat i from 0 to 10
    writeln(s1)
    writeln(s2)
    writeln(s3)
    writeln(s4)
    writeln(s5)
    writeln(s6)
    writeln(s7)
    writeln(inttostr(12345678))
    writeln(hextostr(12345678))


  waitcnt(cnt+clkfreq<<2)

  setscreencolors (3,2,2,0,0,1)
  setbordcolors (0,0,1)

  cls
  box(5,5,20,22)
  setcursorshape($FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF)
  poke(300,255)
  poke(200,64)
  waitcnt(cnt+clkfreq<<2)
'******************************** End of demo ************************************************************************
}}
'*********************************************************************************************************************

'************************************************************************

con
'*************************************************************************
'                                                                        *
'  Cursor functions                                                      *
'                                                                        *
'*************************************************************************
pub waitendvbl
repeat until vblank<>0
repeat until vblank==0

'*************************************************************************
'                                                                        *
'  Cursor functions                                                      *
'                                                                        *
'*************************************************************************

pub cursoron|c_x,c_y

'*************************************************************************
'
'  Switch cursor on
'  Use after cursoroff to restore a cursor in its previous place
'
'*************************************************************************
'cursor:=cursor | $00FF0000
cursor_onoff:=1
c_x:=cursor&255
c_y:=(cursor>>8)&255
putchar(c_x,c_y,95)

pub cursoroff|c_x,c_y

'*************************************************************************
'
'  Switch cursor off
'  To restore it, use cursoron
'
'*************************************************************************
'cursor:=cursor & $FF00FFFF
cursor_onoff:=0
c_x:=cursor&255
c_y:=(cursor>>8)&255
putchar(c_x,c_y,32)

pub setcursor(x,y)

'*************************************************************************
'
'  Set x,y position of cursor and switch it off/on
'
'*************************************************************************

cursor:=(y<<8)+x

pub setcursorx(x)

'*************************************************************************
'
'  Set x position of cursor
'
'*************************************************************************

cursor:=cursor & $FFFFFF00
cursor:=cursor |x

pub setcursory(y)

'*************************************************************************
'
'  Set x position of cursor
'
'*************************************************************************

cursor:=cursor & $FFFF00FF
cursor:=cursor | (y<<8)

{pub setcursorxy(x,y)

'*************************************************************************
'
'  Set x and y position of cursor
'
'*************************************************************************
setcursorx(x)
setcursory(y)
}
{pub setcursorshape(l1,l2,l3,l4)

'*************************************************************************
'
'  Define a cursor shape (16 bytes = 4 longs)
'
'*************************************************************************

cursoroff
waitcnt(cnt+clkfreq/60)
cursor_buf[0]:=l1
cursor_buf[1]:=l2
cursor_buf[2]:=l3
cursor_buf[3]:=l4
cursoron
}
{pub setblinkrate(rate)

'*************************************************************************
'
'  Define a cursor blink rate (in 1/30th of second)
'
'*************************************************************************

cursoroff
waitcnt(cnt+clkfreq/60)
cursor_blink_rate:=rate
cursoron

}
pub getcursorx

return (cursor&255)

pub getcursory

return ((cursor>>8) &255)


pub backspace |cursorx,cursory,temp

cursorx:=cursor&255
cursory:=(cursor>>8)&255
putchar(cursorx,cursory,32)
cursorx -=1
if cursorx<0
  cursorx:=0
  cursory-=1
  if cursory<0
    cursory:=0
putchar(cursorx,cursory,95)
temp:=cursor&$FFFF0000
temp:=temp|cursorx
cursory:=cursory<<8
temp:=temp |cursory
cursor:=temp


'************** End of cursor functions **********************************


'*************************************************************************
'                                                                        *
'  Color functions                                                       *
'                                                                        *
'*************************************************************************

pub setscreencolors(fr,fg,fb,br,bg,bb) |font_color,back_color,i, temp

'*******************************************************************************
'
' Set font and back colors for all screen
'
'*******************************************************************************

font_color:=fr<<6+fg<<4+fb<<2+3
back_color:=br<<6+bg<<4+bb<<2+3
temp:=back_color+font_color<<8+back_color<<16+font_color<<24

repeat i from 196 to 495
  poke (i,temp)


pub setbordcolors(r,g,b) |color, i, temp

'*******************************************************************************
'
' Set border color for all screen
'
'*******************************************************************************

color:=r<<6+g<<4+b<<2+3
temp:=color+color<<8+color<<16+color<<24

repeat i from 187 to 195
  poke (i,temp)



pub setfontcolor(line,pos,r,g,b) | temp, place, color

'*******************************************************************************
'
' Set colors for text at line (0..29) and position (0..19)
' and put them in the color buffer
'
'*******************************************************************************

color:=r<<6+g<<4+b<<2+3

place:=196+(pos>>1)+(line*10)

if (place>495)
  place:=495

temp:=peek(place)

if (pos//2==1) 'high byte
  temp:=temp & $00ffffff
  temp:=temp | (color<<24)

if (pos//2==0) 'high byte
  temp:=temp & $ffff00ff
  temp:=temp | (color<<8)

poke(place,temp)



pub setbackcolor(line,pos,r,g,b) | temp, place, color

'*******************************************************************************
'
' Set colors for background at line (0..29) and position (0..19)
' and put them in the color buffer
'
'*******************************************************************************

color:=r<<6+g<<4+b<<2+3

place:=196+(pos>>1)+(line*10)

if (place>495)
  place:=495


temp:=peek(place)

if (pos//2==1) 'high byte
  temp:=temp & $ff00ffff
  temp:=temp | (color<<16)

if (pos//2==0) 'high byte
  temp:=temp & $ffffff00
  temp:=temp | (color)

poke(place,temp)


pub setbordcolor(line,r,g,b) | temp, place, color

'*******************************************************************************
'
' Set colors for bborder at line (0..29)
' and put them in the color buffer
'
'*******************************************************************************

color:=r<<6+g<<4+b<<2+3

place:=188+(line>>2)
if(line>29)
  place:=187
  line:=line-30

if (place>495)
  place:=495

temp:=peek(place)

if (line//4==0)
  temp:=temp & $ffffff00
  temp:=temp | (color)

if (line//4==1)
  temp:=temp & $ffff00ff
  temp:=temp | (color<<8)


if (line//4==2)
  temp:=temp & $ff00ffff
  temp:=temp | (color<<16)

if (line//4==3)
  temp:=temp & $00ffffff
  temp:=temp | (color<<24)

poke(place,temp)


'*********************************************************************************
'                                                                                *
'  Text functions                                                                *
'                                                                                *
'********************************************************************************

pub outtextxy(x,y,text) | b

'********************************************************************************
'
'             Output string at position x,y
'
'********************************************************************************

b:=@buf+80*y+x
bytemove(b,text,strsize(text))
ifnot (cursor>>16)==0
  waitendvbl

pub putchar(x,y,charcode) |b

'********************************************************************************
'
'             Output a character at position x,y
'
'********************************************************************************

b:=@buf+80*y+x
byte[b]:=charcode&127
ifnot (cursor>>16)==0
  waitendvbl

pub box(x1,y1,x2,y2) |i

'********************************************************************************
'
'             Draw a box at position x1,y1,x2,y2
'
'********************************************************************************

putchar(x1,y1,10)
putchar(x2,y1,9)
putchar(x1,y2,12)
putchar(x2,y2,11)


repeat i from x1+1 to x2-1
  putchar(i,y1,3)
  putchar(i,y2,3)
repeat i from y1+1 to y2-1
  putchar(x1,i,4)
  putchar(x2,i,4)


pub write(text) |b, c_x,c_y,l,i,lines

'********************************************************************************
'
'             Output string at cursor position
'             Set new cursor position at the end of string
'
'********************************************************************************

c_x:=cursor&255
c_y:=(cursor>>8)&255
l:=strsize(text)
b:=80*c_y+c_x
if ((b+l) > 2400)
  lines:=1+ ((b+l-2400) / 80)
  repeat i from 1 to lines
    scrollup
    c_y:=c_y-1
    b:=b-80
outtextxy(c_x,c_y,text)
c_x:=(b+l)//80
c_y:=(b+l)/80

setcursor(c_x,c_y)

pub pchar(chr) |b, c_x,c_y,l,i,lines

'********************************************************************************
'
'             Output char at cursor position
'             Set new cursor position at the end of string
'
'********************************************************************************

   c_x:=cursor&255
   c_y:=(cursor>>8)&255


   case chr
        10:'nichts
        13:writeln(string(" "))      'Return
        8: backspace                 'Back
        9: settab(c_x)               'Tab

        other:
              putchar(c_x,c_y,chr)
              c_x++
              if c_x>79
                 c_x:=0
                 c_y++
              if c_y>29
                 scrollup
                 c_y--
              putchar(c_x,c_y,95)
              setcursor(c_x,c_y)


pub settab(n)|v,c_y

    c_y:=(cursor>>8)&255
    putchar(n,c_y,32)
    case n
         0..8:v:=8
         9..16:v:=16
         17..24:v:=24
         25..32:v:=32
         33..40:v:=40
         41..48:v:=48
         49..56:v:=56
         57..64:v:=64
         65..79:v:=72
    setcursorx(v)
    putchar(v,c_y,95)

pub writeln(text) |b, c_x,c_y,l,i,lines

'********************************************************************************
'
'             Output string at cursor position
'             Set new cursor position at beginning of new line
'
'********************************************************************************

c_x:=cursor&255
c_y:=(cursor>>8)&255
l:=strsize(text)
b:=80*c_y+c_x
if ((b+l) > 2400)
  lines:=1+ ((b+l-2400) / 80)
  repeat i from 1 to lines
    scrollup
    c_y:=c_y-1
    b:=b-80
outtextxy(c_x,c_y,text)
c_x:=(b+l)//80
c_y:=(b+l)/80
if (c_x <> 0)
  c_y+=1
  c_x:=0
  if (c_y==30)
    c_y:=29

    scrollup

setcursor(c_x,c_y)


pub inttostr(i) |q,pos,k,j

'********************************************************************************
'
'             Convert integer to dec string
'             Return a pointer
'
'********************************************************************************

j:=i
pos:=10
k:=0

if (j==0)
  return string ("0")

if (j<0)
  j:=0-j
  k:=45

n_string[11]:=0
repeat while (pos>-1)
  q:=j//10
  q:=48+q
  n_string[pos]:=q
  j:=j/10
  pos-=1
repeat while n_string[0]==48
  bytemove(@n_string,@n_string+1,12)

if k==45
   bytemove(@n_string+1,@n_string,12)
   n_string[0]:=k

result:=@n_string

pub hextostr(i) |q,pos,k,j


'********************************************************************************
'
'             Convert integer to hex string
'             Return a pointer
'
'********************************************************************************

j:=i
pos:=10
k:=0

if (j==0)
  return string ("0")

if (j<0)
  j:=0-j
  k:=45

n_string[11]:=0
repeat while (pos>-1)
  q:=j//16
  if (q>9)
    q:=q+7
  q:=48+q
  n_string[pos]:=q
  j:=j/16
  pos-=1
repeat while n_string[0]==48
  bytemove(@n_string,@n_string+1,12)

if k==45
   bytemove(@n_string+1,@n_string,12)
   n_string[0]:=k
result:=@n_string

pub cls

'**********************************************************************************
'
'            Clear screen, filling it with spaces and not touching any colors
'            Set cursor at 0,0
'
'**********************************************************************************

bytefill(@buf,32,2400)
setcursorx(0)
setcursory(0)


pub scrollup | tmp_cursor

'**********************************************************************************
'
'           Scrolls screen one line up
'
'**********************************************************************************

tmp_cursor:=cursor
cursoroff
waitcnt(cnt+clkfreq/60)
longmove(@buf,@buf+80,580)
bytefill(@buf+2320,32,80)
cursor:=tmp_cursor



pub scrolldown | tmp_cursor

'**********************************************************************************
'
'           Scrolls screen one line down
'
'**********************************************************************************
tmp_cursor:=cursor
cursoroff
waitcnt(cnt+clkfreq/60)
longmove(@buf+80,@buf,580)
bytefill(@buf,32,80)
cursor:=tmp_cursor


pub defchr(code) |i

'**********************************************************************************
'
'           Redefine a character
'           New char definition have to be in chardef table

'**********************************************************************************

repeat i from 0 to 15
  byte[@st_font+code<<4+i]:=chardef[i]



pub start | c1

'**********************************************************************************
'
'           Starts driver
'
'**********************************************************************************

'************************* initialize pointers

buf_ptr:=@buf
line_buf_ptr:=@line_buf
font_ptr:=@st_font
'cursor_buf_ptr:=@cursor_buf

'************************ initialize buffer and cursor

setcursor(0,0)'set cursor on
'setcursorshape(0,0,0,$FFFF0000)
'cursor_blink_rate:=30
cls

'************************ set pixel clock @ 40 MHz

c1:=(160000000/(clkfreq>>16))
frqa_val:=$1000*c1
if clkfreq==80000000
  frqa_val:=$20000000

'************************ set pins for vga according to _vgapins
{
if (_vgapins==0)
  pinmask:=$000000FF
  vcfg_val:=$200000ff
  hsyncmask:= $00000002
  vsyncmask:= $00000001
  hsyncmask2:= $00000002
  vsyncmask2:= $00000001
}
if (_vgapins==1)
  pinmask:=$0000FF00
  vcfg_val:=$200002ff
  hsyncmask:= $00000200
  vsyncmask:= $00000100
  hsyncmask2:= $00000200
  vsyncmask2:= $00000100
{
if (_vgapins==2)
  pinmask:=$00FF0000
  vcfg_val:=$200004ff
  hsyncmask:= $00020000
  vsyncmask:= $00010000
  hsyncmask2:= $00020000
  vsyncmask2:= $00010000

if (_vgapins==3)
  pinmask:=$FF000000
  vcfg_val:=$200006ff
  hsyncmask:= $02000000
  vsyncmask:= $01000000
  hsyncmask2:= $02000000
  vsyncmask2:= $01000000
}
'************************ init cogs and wait until they start

cognew(@vga_start,@buf_ptr)
cognew(@cache_start,@buf_ptr)
waitcnt(cnt+800000)


setscreencolors(2,3,3,0,0,1)
setbordcolors(0,0,1)



pub poke(addr,val)

'********************************************************************************
'
'             Insert a long into display cog ram
'
'********************************************************************************

cmd2:=val
cmd1:=addr
repeat until (cmd1 == $FFFFFFFF)


pub peek(addr)

'********************************************************************************
'
'             Get a long from display cog ram
'
'********************************************************************************

cmd1:=addr+$FF000000
repeat until (cmd1 == $FFFFFFFF)
return cmd2


dat
st_font                 file "st4font.def"


dat
vga_start               org               0


{*****************************************************************************************************************
Display cog. It displays pixels from scanline buffer. The buffer contains 8 scanlines
It is filled in real time with decoding cog/cogs. This structure allows to add anything
to the picture: text, lines, shapes, it have to be computed in real time with another cogs
******************************************************************************************************************}

init_vga                mov buffer_addr,par
                        add buffer_addr,#8
                        rdlong l_b_ptr,buffer_addr      '8 lines line buffer pointer
                        add buffer_addr,#8              'command pointer
                        mov cmd_ptr,buffer_addr
                        add buffer_addr,#16
                        mov vblank_ptr,buffer_addr
                        mov dira,pinmask                'vga pins as output
                        mov ctra,#0
                        movi ctra,#%0_00001_101         'pll div 4
                        mov frqa,frqa_val               '40 MHz pixel clock

                        mov vscl,vscl_val               'init video generator
                        mov vcfg,vcfg_val


'********************   Start of frame rendering *******************************

frame

                        mov l_count,#23                  '23 lines of back porch
bp_loop                 call #blank_line
p2                      djnz l_count,#bp_loop
                        wrlong z,vblank_ptr


'********************** end of back porch


'********************** upper border

                        mov border_color, 187            'it has to be poked here via spin
                        and border_color,mask            'avoid bad sync

                        mov l_count,#60                  '60 lines of upper border
up_frm_loop             call #frame_line

                        djnz l_count,#up_frm_loop

                        mov c_cmd_addr,#196

                        mov b_cmd_addr, #187
                        mov linenum, #0
                        mov l_count,#480                 '480 lines picture
line_loop               call #normal_line

                        djnz l_count,#line_loop

                        mov border_color, 187
                        shr border_color,#8
                        and border_color,mask

                        mov l_count,#60                  '60 lines of lower frame
d_frm_loop              call #frame_line
                        djnz l_count,#d_frm_loop

                        wrlong ffffffff,vblank_ptr
                                                         '1 line of front porch
fp_loop                 call #blank_line

                        mov l_count,#4                   '4 lines of vsync
vbl_loop                call #vsync_line
                        djnz l_count,#vbl_loop

                        jmp  #frame

'********************   End of frame; start of subroutines **********************

'********************   Porches  ************************************************


blank_line
                        mov vscl,vscl_val_bp
                        waitvid blank_color,blank_pixels

                        mov vscl,vscl_val_lb                '800 pixels
                        waitvid blank_color,blank_pixels

                        mov vscl,vscl_val_fp
                        waitvid blank_color,blank_pixels

                        mov vscl,vscl_val_sync
                        waitvid hblk_color,blank_pixels
                        call #pokepeek


blank_line_ret          ret

'********************   Vsync   **************************************************

vsync_line              mov vscl,vscl_val_bp
                        waitvid vblank_color,blank_pixels

                        mov vscl,vscl_val_lb                '800 pixels
                        waitvid vblank_color,blank_pixels

                        mov vscl,vscl_val_fp
                        waitvid vblank_color,blank_pixels

                        mov vscl,vscl_val_sync
                        waitvid vhblk_color,blank_pixels
                        call #pokepeek
vsync_line_ret          ret

'********************   Borders   ****************************************************

frame_line              mov vscl,vscl_val_bp
                        waitvid blank_color,blank_pixels
                        mov vscl,vscl_val

                        mov vscl,vscl_val_lb                '800 pixels of border
fl2                     waitvid border_color,blank_pixels

                        mov vscl,vscl_val_fp
                        waitvid blank_color,blank_pixels

                        mov vscl,vscl_val_sync
                        waitvid hblk_color,blank_pixels
                        call #pokepeek

frame_line_ret          ret


'*******************    Standard picture line display *******************************


normal_line             mov linenum, #480
                        sub linenum,l_count                  'count line numbers from #0
'back porch
                        mov vscl,vscl_val_bp
                        waitvid blank_color,blank_pixels
                        mov l_temp, linenum


                         and l_temp, #%111111 wz
                 if_z    add b_cmd_addr,#1
                 if_z    movs border_cmd, b_cmd_addr
                         nop
border_cmd       if_z    mov border_color, border_cmd
                 if_z    jmp #p3


                         and l_temp, #$0F wz
                if_z     shr border_color, #8
p3                       and border_color, mask



'left border
                        mov vscl,vscl_val_bord
                        waitvid border_color,blank_pixels

                        mov vscl,vscl_val
                        mov p_count,#10                      '640 pixels of picture

                        movs color_cmd,c_cmd_addr

nl                      rdlong temp_buff,l_b_ptr             '20 longs to display
color_cmd               mov std_colors,316
                        and std_colors,mask
                        waitvid std_colors,temp_buff
                        add l_b_ptr,#4

                        shr std_colors, #16

                        rdlong temp_buff,l_b_ptr             '20 longs to display
                        waitvid std_colors,temp_buff
                        add l_b_ptr,#4
                        add color_cmd,#1
                        djnz p_count,#nl
                        add t_cnt, #1
                        add t_cnt2,#1                       'line buffer line counter

'right border
                        mov vscl,vscl_val_bord
                        waitvid border_color,blank_pixels


                        cmp t_cnt, #8           wz           'if 8 lines displayed,
                if_z    sub l_b_ptr,a640
                        cmp t_cnt2,#16          wz
                if_z    add c_cmd_addr,#10



'front porch
                        mov vscl,vscl_val_fp
                        waitvid blank_color,blank_pixels
'hsync
                        mov vscl,vscl_val_sync
                        waitvid hblk_color,blank_pixels
                        call #pokepeek
                        and t_cnt2,#15
                        and t_cnt,#$07                      'don't let buffer line cnt to be >8
normal_line_ret         ret


'************************************************************************
'
' poke/peek code here. We can do one poke/peek at every line
'
'************************************************************************

pokepeek                rdlong command,cmd_ptr

                        cmp command, ffffffff wz          'if $ffffffff
              if_z      jmp #p22                           'then nothing to do
                        add cmd_ptr,#4

                        shl command, #1 wc                'if first bit set, then peek
                        shr command, #1
              if_c      jmp #a_peek

'********************** poke command

                        movd poke_cmd,command
                        rdlong value, cmd_ptr
poke_cmd                mov poke_cmd,value                'dest addr changed
                        jmp #p1

'********************** peek command

a_peek                  movs peek_cmd,command
                        nop
peek_cmd                mov value,peek_cmd
                        wrlong value,cmd_ptr

p1                      sub cmd_ptr, #4

                        wrlong ffffffff, cmd_ptr
p22
pokepeek_ret            ret

'********************** end of peek/poke

'********************   variables *********************************************

l_count                 long    0               ' line counter
p_count                 long    0               ' pixel counter
frqa_val                long    0               ' pixel clock

'********************   values for vscl

vscl_val                long    $00001020       '1 clock/pixel,    32 clock/frame, std vscl for display
vscl_val_sync           long    $00001080       'vscl for hsync,   128 pixels
vscl_val_bord           long    $00001050       'vscl for borders, 80 pixels
vscl_val_fp             long    $00001028       'vscl for front porch
vscl_val_bp             long    $00001058       'vscl for back porch
vscl_val_lb             long    $00001320       'vscl for upper/lower 800 px wide border

'*********************

vcfg_val                long    0               'video vga, 2 colors, 16..23

blank_color             long    $00000000       'idle sync
hblk_color              long    $02020202       'hblk, hsync active
vhblk_color             long    $03030303       'all sync active
vblank_color            long    $01010101       'vsync active
border_color            long    0
std_colors              long    0

blank_pixels            long    0
pinmask                 long    0               ' pin mask for vga to set dira
buffer_addr             long    0
temp_buff               long    $00000000

t_cnt                   long    0
t_cnt2                  long 0
l_b_ptr                 long    0
a640                    long    640
hsyncmask               long    0'
vsyncmask               long    0 '
mask                    long    $FCFCFCFC

linenum                 long    0

cmd_ptr                 long    0
command                 long    0
value                   long    0
ffffffff                long    $ffffffff
z                       long    0

c_cmd_addr              long 196
B_cmd_addr              long 188
l_temp                  long 0

vblank_ptr              long 0
                       fit     187

'color buffer 6 longs/line = 300 longs at the end of cog ram, from 196 to 495
'border buffer, 32 bytes=8 longs, 188..195



dat
cache_start             org     0

{**********************************************************************************************************
 This is a decoding cog. It decodes 80 chars to 4 scan lines and fills scan line buffer for displaying cog.
 There is only a few free time when displaying lines, but this cog is still free when displying borders,
 porches and vsync
 **********************************************************************************************************}

'initialize pointers


                        mov buffer_addr2,par
                        rdlong m_b_ptr2,buffer_addr2        'main buffer

                        add buffer_addr2,#4
                        rdlong f_b_ptr2,buffer_addr2        'font definition buffer

                        add buffer_addr2,#4
                        rdlong l_b_ptr2,buffer_addr2        'scanline buffer

                        mov fbtemp,f_b_ptr2

                        add buffer_addr2,#4
                        rdlong c_s_ptr, buffer_addr2

                        add buffer_addr2,#12
                        mov cur_b_addr, buffer_addr2

                        add buffer_addr2,#4
                        mov cur_bl_addr, buffer_addr2


'wait for vsync


vsync                   waitpeq vsyncmask2,vsyncmask2
                        waitpne vsyncmask2,vsyncmask2


'waiting for 79 lines (porch plus border-4). When 4 scanlines are displaying, 4 next scanlines are preparing,
'so preparation have to start 4 scanlines before main screen area starts displaying

                        mov counter1,#79

loop1                   waitpeq hsyncmask2,hsyncmask2
                        waitpne hsyncmask2,hsyncmask2

'********************   Cursor code here
'********************   Set cursor shape and blink rate

p72                     cmp counter1,#72 wz
              if_nz     jmp #p71


                        rdlong blink_rate,cur_bl_addr

                        rdlong cursor1,c_s_ptr
                        add c_s_ptr,#4
                        rdlong cursor2,c_s_ptr
                        add c_s_ptr,#4
                        rdlong cursor3,c_s_ptr
                        add c_s_ptr,#4
                        rdlong cursor4,c_s_ptr
                        sub c_s_ptr,#12



p71                     cmp counter1,#71 wz
              if_nz     jmp #p70

'********************   switch cursor off and on

                        rdlong cursor_new, cur_b_addr  ' get new cursor parameters
                        mov temp2,cursor_new

                        shr temp2, #16
                        and temp2, #$FF                  'set cursor on/off
                        cmp temp2, #0 wz

                        mov c_on, temp2
              if_nz     jmp #p791                        'cursor is on

                       'cursor is off. Restore char

                        mov temp1,cur_y                ' calculate offset in main buffer
                        shl temp1,#2
                        add temp1,cur_y
                        shl temp1,#4
                        add temp1,cur_x
                        add temp1,m_b_ptr2

                        cmp cached_char,#0 wz          ' if char is cached, restore it
              if_nz     wrbyte cached_char, temp1
                        mov cached_char,#0

                        jmp #p00                        ' don't do anything more if cursor off

p791                    and cursor_new,a_0000ffff
                        cmp cursor_new,cursor_old wz   ' check if position changed
              if_z      jmp #p00                       ' if not, nothing to do

                        'restore cached char

                        mov temp1,cur_y                ' calculate offset in main buffer
                        shl temp1,#2
                        add temp1,cur_y
                        shl temp1,#4
                        add temp1,cur_x
                        add temp1,m_b_ptr2

                        cmp cached_char,#0 wz          ' if char is cached, restore it
              if_nz     wrbyte cached_char, temp1

                        mov cursor_old, cursor_new     ' set new cursor parameters
                        mov cur_y,cursor_new
                        shr cur_y,#8
                        and cur_y,#$FF
                        mov cur_x,cursor_new
                        and cur_x,#$FF

                        jmp #p00

'********************

p70                     cmp counter1,#70 wz
               if_nz    jmp #p69

'********************   Set cursor at position x,y

                        cmp c_on,#0 wz
                        if_z jmp #p00         ' if cursor is off, nothing to do

                        mov temp1,cur_y       ' calculate offset in main buffer
                        shl temp1,#2
                        add temp1,cur_y
                        shl temp1,#4
                        add temp1,cur_x
                        add temp1,m_b_ptr2

                        rdbyte temp2,temp1    ' read char from buffer
                        cmp temp2,#0 wz       ' if zero, cursor position was not changed
              if_z      jmp #p00              ' and nothing to do

                        mov cached_char,temp2 ' someone replaced char at cursor position
                        call #redefine        ' so we have to cache it and redefine char#0
                        wrbyte zero,temp1     ' and write zero at its position
                        jmp #p00

'********************* End of cursor setting code

p69                     cmp counter1,#69 wz '
              if_nz     jmp #p00

'*********************  Cursor blinking code

                        cmp blink_rate,#0 wz
              if_z      jmp #p00
                        add c_count, #1
                        cmp blink_rate,c_count wc
              if_nc     jmp #p00                     'nothing to do

                        mov temp2,fbtemp

                        rdlong temp3,temp2
                        xor temp3,cursor1
                        wrlong temp3,temp2

                        add temp2, #4

                        rdlong temp3,temp2
                        xor temp3,cursor2
                        wrlong temp3,temp2

                        add temp2, #4

                        rdlong temp3,temp2
                        xor temp3,cursor3
                        wrlong temp3,temp2

                        add temp2, #4

                        rdlong temp3,temp2
                        xor temp3,cursor4
                        wrlong temp3,temp2
                        add temp2, #4

                        mov c_count,#0
                        jmp #p00

'*********************  end of cursor blinking


p00                     djnz counter1,#loop1


'now decode 30 lines in sync with hblanks. One decode procedure call decodes 4 scanlines, so we have
'to call it 4 times

                        mov counter2,#30

loop2                   call #decode
                        add l_b_ptr2,#240
                        sub m_b_ptr2,#80
                        add f_b_ptr2,#4

                        call #decode
                        sub l_b_ptr2,#400
                        sub m_b_ptr2,#80
                        add f_b_ptr2,#4

                        call #decode
                        add l_b_ptr2, #240
                        sub m_b_ptr2,#80
                        add f_b_ptr2,#4

                        call #decode
                        sub f_b_ptr2,#12
                        sub l_b_ptr2,#400
                        djnz counter2,#loop2
                        rdlong m_b_ptr2,par
                        jmp #vsync


decode                  mov counter3,#4


loop4                   mov counter1,#20

loop3                   rdbyte char,m_b_ptr2
                        shl char,#4
                        add char,f_b_ptr2
                        rdlong bytes, char
                        add m_b_ptr2,#1
                        wrbyte bytes,l_b_ptr2
                        add l_b_ptr2,#80
                        shr bytes,#8
                        wrbyte bytes,l_b_ptr2
                        add l_b_ptr2,#80
                        shr bytes,#8
                        wrbyte bytes,l_b_ptr2
                        add l_b_ptr2,#80
                        shr bytes,#8
                        wrbyte bytes,l_b_ptr2
                        sub l_b_ptr2,#239

                        djnz counter1,#loop3

                        waitpeq hsyncmask2,hsyncmask2
                        waitpne hsyncmask2,hsyncmask2
                        djnz counter3,#loop4

decode_ret              ret


'redefine char at code 0

redefine                shl temp2,#4
                        add temp2,fbtemp
                        mov temp3,fbtemp

r01                     rdlong temp4,temp2
                        xor temp4,cursor1
                        wrlong temp4,temp3
                        add temp2, #4
                        add temp3, #4
                        rdlong temp4,temp2
                        xor temp4,cursor2
                        wrlong temp4,temp3
                        add temp2, #4
                        add temp3, #4
                        rdlong temp4,temp2
                        xor temp4,cursor3
                        wrlong temp4,temp3
                        add temp2, #4
                        add temp3, #4
                        rdlong temp4,temp2
                        xor temp4,cursor4
                        wrlong temp4,temp3
                        xor blink,ffffffff_2

redefine_ret            ret


zero                    long    0

l_b_ptr2                long    0
f_b_ptr2                long    0
m_b_ptr2                long    0

char                    long    0
bytes                   long    0

counter1                long    0
counter2                long    0
counter3                long    0

buffer_addr2            long    0
hsyncmask2              long    0
vsyncmask2              long    0

ffffffff_2              long $FFFFFFFF
cursor1                 long $ffffffff
cursor2                 long $ffffffff
cursor3                 long $ffffffff
cursor4                 long $ffffffff
cursor_new              long 0
cursor_old              long 0
charnum                 long 0
cur_x                   long 0
cur_y                   long 0
temp1                   long 0
temp2                   long 0
temp3                   long 0
temp4                   long 0
cached_char             long 0
fbtemp                  long 0
c_count                 long 0
c_on                    long 1
cur_b_addr              long 0
blink_rate              long 0
c_s_ptr                 long 0
a_0000ffff              long $0000ffff
blink                   long 0
cur_bl_addr             long 0

                            fit 496


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
