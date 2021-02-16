{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Ingo Kripahle                                                                                 │
│ Copyright (c) 2010 Ingo Kripahle                                                                     │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : drohne235@googlemail.com
System          : TriOS
Name            : [I]nput-[O]utput-[S]ystem - System-API
Chip            : Regnatix
Typ             : Objekt
Version         : 01
Subversion      : 1
Funktion        : System-API - Schnittstelle der Anwendungen zu allen Systemfunktionen

Regnatix
                  system        : Systemübergreifende Routinen
                  loader        : Routinen um BIN-Dateien zu laden
                  ramdisk       : Strukturierte Speicherverwaltung: Ramdisk
                  eram          : Einfache Speicherverwaltung: Usermem
                  bus           : Kommunikation zu Administra und Bellatrix

Administra
                  sd-card       : FAT16 Dateisystem auf SD-Card
                  scr           : Screeninterface
                  hss           : Hydra-Soundsystem
                  sfx           : Sound-FX

Bellatrix
                  key           : Keyboardroutinen
                  screen        : Bildschirmsteuerung
                  g0            : grafikmodus 0,TV-Modus 256 x 192 Pixel, Vektorengine

Venatrix          diverse Buserweiterungen


Komponenten     : -
COG's           : -
Logbuch         :

13-03-2009-dr235  - string für parameterübergabe zwischen programmen im eram eingerichtet
19-11-2008-dr235  - erste version aus dem ispin-projekt extrahiert
26-03-2010-dr235  - errormeldungen entfernt (mount)
05-08-2010-dr235  - speicherverwaltung für eram eingefügt
18-09-2010-dr235  - fehler in bus_init behoben: erste eram-zelle wurde gelöscht durch falsche initialisierung
25-11-2011-dr235  - funktionsset für grafikmodus 0 eingefügt
28-11-2011-dr235  - sfx_keyoff, sfx_stop eingefügt
01-12-2011-dr235  - printq zugefügt: ausgabe einer zeichenkette ohne steuerzeichen
25-01-2012-dr235  - korrektur char_ter_bs
15-09-2013-zille9 - erste Venatrix-Routinen bus_getchar3 und bus_putchar3 ,put/getword,long hinzugefügt

Notizen         :

 --------------------------------------------------------------------------------------------------------- }}

CON 'Signaldefinitionen
'signaldefinition regnatix
#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#8,     A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10               'adressbus
#19,    REG_RAM1,REG_RAM2                               'selektionssignale rambank 1 und 2
#21,    REG_PROP1,REG_PROP2                             'selektionssignale für administra und bellatrix
#23,    REG_AL                                          'strobesignal für adresslatch
#24,    REG_AL2                                         'strobesignal für Funktionslatch
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal

CON 'Zeichencodes
'zeichencodes
CHAR_RETURN     = $0D                                   'eingabezeichen
CHAR_NL         = $0D                                   'newline
CHAR_SPACE      = $20                                   'leerzeichen
CHAR_BS         = $08                                   'tastaturcode backspace
CHAR_TER_BS     = $08                                   'terminalcode backspace
CHAR_ESC        = $1B
CHAR_LEFT       = $02
CHAR_RIGHT      = $03
CHAR_UP         = $0B
CHAR_DOWN       = $0A
KEY_CTRL        = $02
KEY_ALT         = $04
KEY_OS          = $08

CON 'Systemvariablen
'systemvariablen
LOADERPTR       = $0FFFFB       '4 Byte                 'Zeiger auf Loader-Register im hRAM
MAGIC           = $0FFFFA       '1 Byte                 'Warmstartflag
SIFLAG          = $0FFFF9       '1 byte                 'Screeninit-Flag
BELDRIVE        = $0FFFED       '12 Byte                'Dateiname aktueller Grafiktreiber
PARAM           = $0FFFAD       '64 Byte                'Parameterstring
RAMDRV          = $0FFFAC       '1 Byte                 'Ramdrive-Flag
RAMEND          = $0FFFA8       '4 Byte                 'Zeiger auf oberstes freies Byte (einfache Speicherverwaltung)
RAMBAS          = $0FFFA4       '4 Byte                 'Zeiger auf unterstes freies Byte (einfache Speicherverwaltung)

SYSVAR          = $0FFFA3                               'Adresse des obersten freien Bytes, darüber folgen Systemvariablen

CON 'Sonstiges
'CNT_HBEAT       = 5_000_0000                            'blinkgeschw. front-led
DB_IN           = %00000110_11111111_11111111_00000000  'maske: dbus-eingabe
DB_OUT          = %00000110_11111111_11111111_11111111  'maske: dbus-ausgabe

OS_TIBLEN       = 64                                    'größe des inputbuffers
ERAM            = 1024 * 512 * 2                        'größe eram
HRAM            = 1024 * 32                             'größe hram

RMON_ZEILEN     = 16                                    'speichermonitor - angezeigte zeilen
RMON_BYTES      = 8                                     'speichermonitor - zeichen pro byte

STRCOUNT        = 64                                    'größe des stringpuffers

CON 'ADMINISTRA-FUNKTIONEN --------------------------------------------------------------------------



'dateiattribute
#0,     F_SIZE
        F_CRDAY
        F_CRMONTH
        F_CRYEAR
        F_CRSEC
        F_CRMIN
        F_CRHOUR
        F_ADAY
        F_AMONTH
        F_AYEAR
        F_CDAY
        F_CMONTH
        F_CYEAR
        F_CSEC
        F_CMIN
        F_CHOUR
        F_READONLY
        F_HIDDEN
        F_SYSTEM
        F_DIR
        F_ARCHIV
'dir-marker
#0,     DM_ROOT
        DM_SYSTEM
        DM_USER
        DM_A
        DM_B
        DM_C



CON 'BELLATRIX-FUNKTIONEN --------------------------------------------------------------------------

' einzeichen-steuercodes

#$0,    BEL_CMD              'esc-code für zweizeichen-steuersequenzen
        BEL_LEFT
        BEL_HOME
        BEL_POS1
        BEL_CURON
        BEL_CUROFF
        BEL_SCRLUP
        BEL_SCRLDOWN
        BEL_BS
        BEL_TAB

' zweizeichen-steuersequenzen
' [BEL_CMD][...]

#$1,    BEL_KEY_STAT
        BEL_KEY_CODE
        BEL_DPL_SETY'SCRCMD           'esc-code für dreizeichen-sequenzen
        BEL_KEY_SPEC
        BEL_DPL_MOUSE
        BEL_SCR_CHAR
        BEL_BLKTRANS
        BEL_DPL_SETX
        BEL_LD_MOUSEBOUND
        BEL_MOUSEX
        BEL_MOUSEY
        BEL_MOUSEZ
        BEL_MOUSE_PRESENT
        BEL_MOUSE_BUTTON
        BEL_BOXSIZE
        BEL_CURSORCOLOR
        BEL_CURSORRATE
        BEL_BOXCOLOR
        BEL_ERS_3DBUTTON
        BEL_SCOLLUP
        BEL_SCOLLDOWN
        BEL_DPL_3DBOX
        BEL_DPL_3DFRAME
        BEL_DPL_2DBOX
        BEL_Send_BUTTON
        BEL_SCROLLSTRING
        BEL_DPL_STRING
        BEL_DPL_SETXalt
        BEL_DPL_SETYalt
        BEL_LD_MOUSEPOINTER
        BEL_DPL_SETPOS
        BEL_DPL_TILE
        BEL_DPL_WIN
        BEL_DPL_TCOL
        BEL_LD_TILESET
        BEL_DPL_PIC
        BEL_GETX
        BEL_GETY
        BEL_DPL_LINE
        BEL_DPL_PIXEL
        BEL_SPRITE_PARAM
        BEL_SPRITE_POS
        BEL_ACTOR
        BEL_ACTORPOS
        BEL_ACT_KEY
        BEL_SPRITE_RESET
        BEL_SPRITE_MOVE
        BEL_SPRITE_SPEED
        BEL_GET_COLLISION
        BEL_GET_ACTOR_POS
        BEL_SEND_BLOCK
        BEL_FIRE_PARAM
        BEL_FIRE
        BEL_DPL_PALETTE
        BEL_DEL_WINDOW
        BEL_SET_TITELSTATUS
        BEL_BACK
        Bel_REST
        BEL_WINDOW
        BEL_GET_WINDOW
        BEL_CHANGE_BACKUP
        BEL_PRINTFONT
        BEL_WINDOW_ATTR


#80,    BMGR_WIN_DEFINE
        BMGR_FREI
        BMGR_WIN_SET
        BMGR_FREI2
        BMGR_WIN_GETCOLS
        BMGR_WIN_GETROWS
        BMGR_WIN_OFRAME
        BMGR_LOAD
        BMGR_WSCR
        BMGR_DSCR
        BMGR_GETCOLOR
        BMGR_SETCOLOR
        BMGR_GETRESX
        BMGR_GETRESY
        BMGR_GETCOLS
        BMGR_GETROWS
        BMGR_GETCOGS
        BMGR_GETSPEC
        BMGR_GETVER
        BMGR_REBOOT

' dreizeichen-steuersequenzen
' [BEL_CMD][BEL_SCRCMD][...]

#$1,    BEL_SETCUR
        BEL_SETX
        BEL_SETY
        BEL_GETXalt
        BEL_GETYalt
        BEL_SETCOL
        BEL_SLINE
        BEL_ELINE
        BEL_SINIT
        BEL_TABSET

con ' I2C-Funktionen und Steuercodes
'' uMite I2C Connection Settings
   SDA_pin       = 29'14         ''IMPORTANT NOTE:
   SCL_pin       = 28'18 für Hive-Max 20'15         ''THESE TWO LINES REQUIRE 10K PULL-UP RESISTORS
   Bitrate       = 400_000
   Micr_Adr      = $42

'****************** Micromite-Befehlserweiterung über I2C *****************************************

   SWITCH_MODE  = 2
   MICR_CLS     = 204
   CLEAR_REG    = 230
   DMPL_PLAY    = 240
   DMPL_PAUSE   = 241
   DMPL_STOP    = 242
   MICR_REBOOT  = 190
   MICR_MODE2   = 191
   MICR_MODE3   = 192
   MICR_MODE4   = 193
   MICR_MODE5   = 194
   MICR_MODE6   = 195
   MICR_MODE7   = 196
   MICR_MODE8   = 197
   MICRSD_CLOSE = 189
   MICRSD_GETC  = 186
   MICRSD_PUTC  = 185
   MICRSD_APPEND= 183
   MICRSD_WRITE = 182
   MICRSD_READ  = 181
   GET_FILENAME = 180

con'' Mode2+6

    mode2_color   = 20   'Farbe ändern
    text_color    = 21
    back_color    = 22
    Cursor_ON     = 30
    Cursor_OFF    = 31
    C_Set         = 32
    C_Get         = 33
    plot          = 34
    line_draw     = 35
    draw_box      = 36
    mode6_color   = 37
    re_define     = 38
    bt_redefine   = 39
    petright      = 40
    petleft       = 41

obj
    ram_rw :"ram"
    gc     :"glob-microm"

VAR
        long lflagadr                                   'adresse des loaderflag
        byte strpuffer[STRCOUNT]                        'stringpuffer
        byte tmptime
        byte serial                                     'serielle Schnittstelle geöffnet?
        byte parapos
        'byte register[16]

PUB start: wflag                                    'system: ios initialisieren
''funktionsgruppe               : system
''funktion                      : ios initialisieren
''eingabe                       : -
''ausgabe                       : wflag - 0: kaltstart
''                              :         1: warmstart
''busprotokoll                  : -

  bus_init                                              'bus initialisieren
  ram_rw.start                                          'Ram-Treiber starten

  serial:=0                                             'serielle Schnittstelle geschlossen

  sddmact(DM_USER)                                      'wieder in userverzeichnis wechseln
  lflagadr := ram_rdlong(LOADERPTR)                     'adresse der loader-register setzen

  if ram_rdbyte(MAGIC) == 235
    'warmstart
    wflag := 1

  else
    'kaltstart
    ram_wrbyte(235,MAGIC)
    wflag := 0
    ram_wrbyte(0,RAMDRV)                         'Ramdrive ist abgeschaltet


PUB stop                                                'loader: beendet anwendung und startet os
''funktionsgruppe               : system
''funktion                      : beendet die laufende  anwendung und kehrt zum os (reg.sys) zurück
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : -
  ram_rw.stop
  'ser.stop
  'sd_mount
  sddmact(DM_ROOT)
  sdopen("r",@regsys)
  ldbin(@regsys)
  repeat

'PUB startram                                            'system: initialisierung des systems bei ram-upload
''funktionsgruppe               : system
''funktion                      : ios initialisieren - wenn man zu testzwecken das programm direkt in den ram
''                              : überträgt und startet, bekommen alle props ein reset, wodurch bellatrix auf
''                              : einen treiber wartet. für testzwecke erledigt diese routine den upload des
''                              : standard-vga-treibers.
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : -

'  sdmount                                               'sd-karte mounten
'  bload(@belsys)                                        'vga-treiber zu bellatrix übertragen

PUB paraset(stradr) | i,c                               'system: parameter --> eram
''funktionsgruppe               : system
''funktion                      : parameter --> eram - werden programme mit dem systemloader gestartet, so kann
''                              : mit dieser funktion ein parameterstring im eram übergeben werden. das gestartete
''                              : programm kann diesen dann mit "parastart" & "paranext" auslesen und verwenden
''eingabe                       : -
''ausgabe                       : stradr - adresse des parameterstrings
''busprotokoll                  : -

  paradel                                               'parameterbereich löschen
  repeat i from 0 to 63                                 'puffer ist mx. 64 zeichen lang
    c := byte[stradr+i]
    ram_wrbyte(c,PARAM+i)
    if c == 0                                           'bei stringende vorzeitig beenden
      return

pub paracopy(adr)|i,c
  paradel                                               'parameterbereich löschen
  repeat i from 0 to 63                                 'puffer ist mx. 64 zeichen lang
    c := ram_rdbyte(adr++)
    ram_wrbyte(c,PARAM+i)
    if c == 0                                           'bei stringende vorzeitig beenden
      return
PUB paradel | i                                         'system: parameterbereich löschen
''funktionsgruppe               : system
''funktion                      : parameterbereich im eram löschen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : -

  repeat i from 0 to 63
    ram_wrbyte(0,PARAM+i)

PUB parastart                                           'system: setzt den zeiger auf parameteranfangsposition
''funktionsgruppe               : system
''funktion                      : setzt den index auf die parameteranfangsposition
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : -

  parapos := 0

PUB paranext(stradr): err | i,c                         'system: überträgt den nächsten parameter in stringdatei
''funktionsgruppe               : system
''funktion                      : überträgt den nächsten parameter in stringdatei
''eingabe                       : stradr - adresse einer stringvariable für den nächsten parameter
''ausgabe                       : err - 0: kein weiterer parameter
''                              :       1: parameter gültig
''busprotokoll                  : -

  if ram_rdbyte(PARAM+parapos) <> 0                   'stringende?
    repeat until ram_rdbyte(PARAM+parapos) > CHAR_SPACE 'führende leerzeichen ausblenden
      parapos++
    i := 0
    repeat                                              'parameter kopieren
      c := ram_rdbyte(PARAM + parapos++)
      if c <> CHAR_SPACE                                'space nicht kopieren
        byte[stradr++] := c
    until (c == CHAR_SPACE) or (c == 0)
    byte[stradr] := 0                                   'string abschließen
    return 1
  else
    return 0

PUB reggetcogs:regcogs |i,c,cog[8]                      'system: fragt freie cogs von regnatix ab
''funktionsgruppe               : system
''funktion                      : fragt freie cogs von regnatix ab
''eingabe                       : -
''ausgabe                       : regcogs - anzahl der belegten cogs
''busprotokoll                  : -

  regcogs := i := 0
  repeat 'loads as many cogs as possible and stores their cog numbers
    c := cog[i] := cognew(@entry, 0)
    if c=>0
      i++
  while c => 0
  regcogs := i
  repeat 'unloads the cogs and updates the string
    i--
    if i=>0
      cogstop(cog[i])
  while i=>0  

PUB ldbin(stradr) | len,i,stradr2               'loader: startet bin-datei über loader
''funktionsgruppe               : system
''funktion                      : startet bin-datei über den systemloader
''eingabe                       : stradr - adresse eines strings mit dem dateinamen der bin-datei
''ausgabe                       : -
''busprotokoll                  : -

  len := strsize(stradr)
  stradr2 := lflagadr + 1                               'adr = flag, adr + 1 = string
  repeat i from 0 to len - 1                            'string in loadervariable kopieren
         byte[stradr2][i] := byte[stradr][i]
  byte[stradr2][++i] := 0                               'string abschließen
  byte[lflagadr][0] := 1                                'loader starten

PUB os_error(err):error                                 'sys: fehlerausgabe

  {if err
    printnl
    print(string("Fehlernummer : "))
    printdec(err)
    print(string(" : $"))
    printhex(err,2)
    printnl
    print(string("Fehler       : "))
    case err
      0:  print(string("no error"))
      1:  print(string("fsys unmounted"))
      2:  print(string("fsys corrupted"))
      3:  print(string("fsys unsupported"))
      4:  print(string("not found"))
      5:  print(string("file not found"))
      6:  print(string("dir not found"))
      7:  print(string("file read only"))
      8:  print(string("end of file"))
      9:  print(string("end of directory"))
      10: print(string("end of root"))
      11: print(string("dir is full"))
      12: print(string("dir is not empty"))
      13: print(string("checksum error"))
      14: print(string("reboot error"))
      15: print(string("bpb corrupt"))
      16: print(string("fsi corrupt"))
      17: print(string("dir already exist"))
      18: print(string("file already exist"))
      19: print(string("out of disk free space"))
      20: print(string("disk io error"))
      21: print(string("command not found"))
      22: print(string("timeout"))
      23: print(string("out of memory"))
      OTHER: print(string("undefined"))}
    'printnl
  error := err

OBJ' SERIAL-FUNKTIONEN
CON' -------------------------------------------------- Funktionen der seriellen Schnittstelle -----------------------------------------------------------
{pub seropen(bd)            'ser. Schnittstelle virtuell öffnen
    ser.start(TX_PIN,RX_PIN,%0000,BD)                           'serielle Schnittstelle starten
'    serial:=1

pub serclose           'ser. Schnittstelle virtuell schliessen
    'serial:=0
    ser.stop
pub serget:c           'warten bis Zeichen an ser. Schnittstelle anliegt
    c:=ser.rx
pub serread:c          ' Zeichen von ser. Schnittstelle lesen ohne zu warten -1 wenn kein Zeichen da ist
    c:=ser.rxcheck

pub sertx(c)
    ser.tx(c)

pub serdec(c)
    ser.dec(c)

pub serstr(strg)
    ser.str(strg)

pub serflush
    ser.rxflush

pub ser_rxtime(ms)
    ser.rxtime(ms)
    }
OBJ '' A D M I N I S T R A

CON ''------------------------------------------------- CHIP-MANAGMENT

PUB admload(stradr)                                 'chip-mgr: neuen administra-code booten
''funktionsgruppe               : cmgr
''funktion                      : administra mit neuem code booten
''busprotokoll                  : [096][sub_putstr.fn]
''                              : fn - dateiname des neuen administra-codes

  bus_putchar1(gc#a_mgrALoad)      'aktuelles userdir retten
  bus_putstr1(stradr)
  waitcnt(cnt + clkfreq*3)      'warte bis administra fertig ist

PUB admgetver:ver                                       'chip-mgr: version abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''busprotokoll                  : [098][sub_getlong.ver]
''                              : ver - version
''                  +----------
''                  |  +------- system     
''                  |  |  +---- version    (änderungen)
''                  |  |  |  +- subversion (hinzufügungen)
''version :       $00_00_00_00
''

  bus_putchar1(gc#a_mgrGetVer)
  ver := bus_getlong1

PUB admgetspec:spec                                     'chip-mgr: spezifikation abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''busprotokoll                  : [089][sub_getlong.spec]
''                              : spec - spezifikation
''
''                                          +---------- com
''                                          | +-------- i2c
''                                          | |+------- rtc
''                                          | ||+------ lan
''                                          | |||+----- sid
''                                          | ||||+---- wav
''                                          | |||||+--- hss
''                                          | ||||||+-- bootfähig
''                                          | |||||||+- dateisystem
''spezifikation : %00000000_00000000_00000000_01001111

  bus_putchar1(gc#a_mgrGetSpec)
  spec := bus_getlong1

PUB admgetcogs:cogs                                     'chip-mgr: verwendete cogs abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage wie viele cogs in benutzung sind
''busprotokoll                  : [097][get.cogs]
''                              : cogs - anzahl der belegten cogs

  bus_putchar1(gc#a_mgrGetCogs)
  cogs := bus_getchar1

PUB admreset                                            'chip-mgr: administra reset
''funktionsgruppe               : cmgr
''funktion                      : reset im administra-chip auslösen - loader aus dem eeprom wird neu geladen
''busprotokoll                  : -

  bus_putchar1(gc#a_mgrReboot)

'PUB admdebug: wert                                      'chip-mgr: debug-funktion

'  bus_putchar1(AMGR_DEBUG)
'  wert := bus_getlong1

CON ''------------------------------------------------- SD_LAUFWERKSFUNKTIONEN

PUB sdmount: err                                        'sd-card: mounten
''funktionsgruppe               : sdcard
''funktion                      : eingelegtes volume mounten
''busprotokoll                  : [001][get.err]
''                              : err - fehlernummer entspr. list

  bus_putchar1(gc#a_SDMOUNT)
  err := bus_getchar1
  
PUB sddir                                               'sd-card: verzeichnis wird geöffnet
''funktionsgruppe               : sdcard
''funktion                      : verzeichnis öffnen
''busprotokoll                  : [002]

  bus_putchar1(gc#a_SDOPENDir)

PUB sdnext| flag                               'sd-card: nächster dateiname aus verzeichnis
''funktionsgruppe               : sdcard
''funktion                      : nächsten eintrag aus verzeichnis holen
''busprotokoll                  : [003][get.status=0]
''                              : [003][get.status=1][sub_getstr.fn]
''                              : status - 1 = gültiger eintrag
''                              :          0 = es folgt kein eintrag mehr
''                              : fn - verzeichniseintrag string

    bus_putchar1(gc#a_SDNEXTFILE)                           'kommando: nächsten eintrag holen
    flag := bus_getchar1                                'flag empfangen
    if flag 
      return bus_getstr1
    else
      return 0

PUB sdopen(modus,stradr):err | len,i                    'sd-card: datei öffnen
''funktionsgruppe               : sdcard
''funktion                      : eine bestehende datei öffnen
''busprotokoll                  : [004][put.modus][sub_putstr.fn][get.error]
''                              : modus - "A" Append, "W" Write, "R" Read (Großbuchstaben!)
''                              : fn - name der datei
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDOPEN)
  bus_putchar1(modus)
  len := strsize(stradr)
  bus_putchar1(len)
  repeat i from 0 to len - 1
    bus_putchar1(byte[stradr++])
  err := bus_getchar1

PUB sdclose:err                                         'sd-card: datei schließen
''funktionsgruppe               : sdcard
''funktion                      : die aktuell geöffnete datei schließen
''busprotokoll                  : [005][get.error]
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDCLOSE)
  err := bus_getchar1

PUB sdgetc: char                                        'sd-card: zeichen aus datei lesen
''funktionsgruppe               : sdcard
''funktion                      : zeichen aus datei lesen
''busprotokoll                  : [006][get.char]
''                              : char - gelesenes zeichen

  bus_putchar1(gc#a_SDGETC)
  char := bus_getchar1

PUB sdputc(char)                                        'sd-card: zeichen in datei schreiben
{{sdputc(char) - sd-card: zeichen in datei schreiben}}
  bus_putchar1(gc#a_SDPUTC)
  bus_putchar1(char)

PUB sdgetstr(stringptr,len)                             'sd-card: eingabe einer zeichenkette
  repeat len
    byte[stringptr++] := bus_getchar1

PUB sdputstr(stringptr)                                 'sd-card: ausgabe einer zeichenkette (0-terminiert)
{{sdstr(stringptr) - sd-card: ausgabe einer zeichenkette (0-terminiert)}}
  repeat strsize(stringptr)
    sdputc(byte[stringptr++])

PUB sddec(value) | i                                    'sd-card: dezimalen zahlenwert auf bildschirm ausgeben
{{sddec(value) - sd-card: dezimale bildschirmausgabe zahlenwertes}}
  if value < 0                                          'negativer zahlenwert
    -value
    sdputc("-")
  i := 1_000_000_000
  repeat 10                                             'zahl zerlegen
    if value => i
      sdputc(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      sdputc("0")
    i /= 10                                             'n?chste stelle

PUB sdeof: eof                                          'sd-card: eof abfragen
''funktionsgruppe               : sdcard
''funktion                      : eof abfragen
''busprotokoll                  : [030][get.eof]
''                              : eof - eof-flag

  bus_putchar1(gc#a_SDEOF)
  eof := bus_getchar1
pub sdpos:c
    bus_putchar1(gc#a_SDPOS)
    c:=bus_getlong1

pub sdcopy(cm,pm,source)
    bus_putchar1(gc#a_SDCOPY)
    bus_putlong1(cm)
    bus_putlong1(pm)

    bus_putstr1(source)


PUB sdgetblk(count,bufadr) | i                          'sd-card: block lesen
''funktionsgruppe               : sdcard
''funktion                      : block aus datei lesen
''busprotokoll                  : [008][sub_putlong.count][get.char(1)]..[get.char(count)]
''                              : count - anzahl der zu lesenden zeichen
''                              : char - gelesenes zeichen

  i := 0
  bus_putchar1(gc#a_SDGETBLK)
  bus_putlong1(count)
  repeat count
    byte[bufadr][i++] := bus_getchar1
    
PUB sdputblk(count,bufadr) | i                          'sd-card: block schreiben
''funktionsgruppe               : sdcard
''funktion                      : zeichen in datei schreiben
''busprotokoll                  : [007][put.char]
''                              : char - zu schreibendes zeichen

  i := 0
  bus_putchar1(gc#a_SDPUTBLK)
  bus_putlong1(count)
  repeat count
    bus_putchar1(byte[bufadr][i++])
con'************************************************ Blocktransfer test modifizieren fuer Tiledateien und Datendateien (damit es schneller geht ;-) **************************************
PUB sdxgetblk(adr,count)|i                              'sd-card: block lesen --> eRAM
''funktionsgruppe               : sdcard
''funktion                      : block aus datei lesen und in ramdisk speichern
''busprotokoll                  : [008][sub_putlong.count][get.char(1)]..[get.char(count)]
''                              : count - anzahl der zu lesenden zeichen
''                              : char - gelesenes zeichen

  i := 0
  bus_putchar1(gc#a_SDGETBLK)
  bus_putlong1(count)          'laenge der Datei in byte
  repeat count
     ram_wrbyte(bus_getchar1,adr++)

con '*********************************************** Blocktransfer test **************************************************************************************************
PUB sdxputblk(adr,count)                              'sd-card: block schreiben <-- eRAM
''funktionsgruppe               : sdcard
''funktion                      : zeichen aus ramdisk in datei schreiben
''busprotokoll                  : [007][put.char]
''                              : char - zu schreibendes zeichen

  bus_putchar1(gc#a_SDPUTBLK)
  bus_putlong1(count)
  repeat count
    bus_putchar1(ram_rdbyte(adr++))'rd_get(fnr))

PUB sdseek(wert)                                        'sd-card: zeiger auf byteposition setzen
''funktionsgruppe               : sdcard
''funktion                      : zeiger in datei positionieren
''busprotokoll                  : [010][sub_putlong.pos]
''                              : pos - neue zeichenposition in der datei

  bus_putchar1(gc#a_SDSEEK)
  bus_putlong1(wert)

PUB sdfattrib(anr): attrib                              'sd-card: dateiattribute abfragen
''funktionsgruppe               : sdcard
''funktion                      : dateiattribute abfragen
''busprotokoll                  : [011][put.anr][sub_getlong.wert]
''                              : anr - 0  = Dateigröße
''                              :       1  = Erstellungsdatum - Tag
''                              :       2  = Erstellungsdatum - Monat
''                              :       3  = Erstellungsdatum - Jahr
''                              :       4  = Erstellungsdatum - Sekunden
''                              :       5  = Erstellungsdatum - Minuten
''                              :       6  = Erstellungsdatum - Stunden
''                              :       7  = Zugriffsdatum - Tag
''                              :       8  = Zugriffsdatum - Monat
''                              :       9  = Zugriffsdatum - Jahr
''                              :       10 = Änderungsdatum - Tag
''                              :       11 = Änderungsdatum - Monat
''                              :       12 = Änderungsdatum - Jahr
''                              :       13 = Änderungsdatum - Sekunden
''                              :       14 = Änderungsdatum - Minuten
''                              :       15 = Änderungsdatum - Stunden
''                              :       16 = Read-Only-Bit
''                              :       17 = Hidden-Bit
''                              :       18 = System-Bit
''                              :       19 = Direktory
''                              :       20 = Archiv-Bit
''                              : wert - wert des abgefragten attributes


  bus_putchar1(gc#a_SDFATTRIB)
  bus_putchar1(anr)
  attrib := bus_getlong1                               
  
  
PUB sdvolname: stradr                            'sd-card: volumelabel abfragen
''funktionsgruppe               : sdcard
''funktion                      : name des volumes überragen
''busprotokoll                  : [012][sub_getstr.volname]
''                              : volname - name des volumes
''                              : len   - länge des folgenden strings

  bus_putchar1(gc#a_SDVOLNAME)                              'kommando: volumelabel abfragen
  return bus_getstr1
  
PUB sdcheckmounted: flag                                'sd-card: test ob volume gemounted ist
''funktionsgruppe               : sdcard
''funktion                      : test ob volume gemounted ist
''busprotokoll                  : [013][get.flag]
''                              : flag  - 0: unmounted
''                              :         1: mounted

  bus_putchar1(gc#a_SDCHECKMOUNTED)
  return bus_getchar1
  
PUB sdcheckopen: flag                                   'sd-card: test ob datei geöffnet ist
''funktionsgruppe               : sdcard
''funktion                      : test ob eine datei geöffnet ist
''busprotokoll                  : [014][get.flag]
''                              : flag  - 0: not open
''                              :         1: open

  bus_putchar1(gc#a_SDCHECKOPEN)
  return bus_getchar1

PUB sdcheckused                                         'sd-card: abfrage der benutzten sektoren
''funktionsgruppe               : sdcard
''funktion                      : anzahl der benutzten sektoren senden 
''busprotokoll                  : [015][sub_getlong.used]
''                              : used - anzahl der benutzten sektoren

  bus_putchar1(gc#a_SDCHECKUSED)
  return bus_getlong1

PUB sdcheckfree                                         'sd_card: abfrage der freien sektoren
''funktionsgruppe               : sdcard
''funktion                      : anzahl der freien sektoren senden 
''busprotokoll                  : [016][sub_getlong.free]
''                              : free - anzahl der freien sektoren

  bus_putchar1(gc#a_SDCHECKFREE)
  return bus_getlong1

PUB sdnewfile(stradr):err                               'sd_card: neue datei erzeugen
''funktionsgruppe               : sdcard
''funktion                      : eine neue datei erzeugen 
''busprotokoll                  : [017][sub_putstr.fn][get.error]
''                              : fn - name der datei
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDNEWFILE)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdnewdir(stradr):err                                'sd_card: neues verzeichnis erzeugen
''funktionsgruppe               : sdcard
''funktion                      : ein neues verzeichnis erzeugen
''busprotokoll                  : [018][sub_putstr.fn][get.error]
''                              : fn - name des verzeichnisses
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDNEWDIR)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sddel(stradr):err                                   'sd_card: datei/verzeichnis löschen
''funktionsgruppe               : sdcard
''funktion                      : eine datei oder ein verzeichnis löschen
''busprotokoll                  : [019][sub_putstr.fn][get.error]
''                              : fn - name des verzeichnisses oder der datei
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDDEL)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdrename(stradr1,stradr2):err                       'sd_card: datei/verzeichnis umbenennen
''funktionsgruppe               : sdcard
''funktion                      : datei oder verzeichnis umbenennen
''busprotokoll                  : [020][sub_putstr.fn1][sub_putstr.fn2][get.error]
''                              : fn1 - alter name 
''                              : fn2 - neuer name 
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDRENAME)
  bus_putstr1(stradr1)
  bus_putstr1(stradr2)
  err := bus_getchar1

PUB sdchattrib(stradr1,stradr2):err                     'sd-card: attribute ändern
''funktionsgruppe               : sdcard
''funktion                      : attribute einer datei oder eines verzeichnisses ändern
''busprotokoll                  : [021][sub_putstr.fn][sub_putstr.attrib][get.error]
''                              : fn - dateiname
''                              : attrib - string mit attributen (AHSR)
''                              : error - fehlernummer entspr. liste

  bus_putchar1(gc#a_SDCHATTRIB)
  bus_putstr1(stradr1)
  bus_putstr1(stradr2)
  err := bus_getchar1

PUB sdchdir(stradr):err                                 'sd-card: verzeichnis wechseln
''funktionsgruppe               : sdcard
''funktion                      : verzeichnis wechseln
''busprotokoll                  : [022][sub_putstr.fn][get.error]
''                              : fn - name des verzeichnisses
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDCHDIR)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdformat(stradr):err                                'sd-card: medium formatieren
''funktionsgruppe               : sdcard
''funktion                      : medium formatieren
''busprotokoll                  : [023][sub_putstr.vlabel][get.error]
''                              : vlabel - volumelabel
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDFORMAT)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sdunmount:err                                       'sd-card: medium abmelden
''funktionsgruppe               : sdcard
''funktion                      : medium abmelden
''busprotokoll                  : [024][get.error]
''                              : error - fehlernummer entspr. list

  bus_putchar1(gc#a_SDUNMOUNT)
  err := bus_getchar1

PUB sddmact(marker):err                                 'sd-card: dir-marker aktivieren
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker wird aktiviert
''busprotokoll                  : [025][put.dmarker][get.error]
''                              : dmarker - dir-marker      
''                              : error   - fehlernummer entspr. list

  bus_putchar1(gc#a_SDDMACT)
  bus_putchar1(marker)
  err := bus_getchar1

PUB sddmset(marker)                                     'sd-card: dir-marker setzen
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker mit dem aktuellen verzeichnis setzen
''busprotokoll                  : [026][put.dmarker]
''                              : dmarker - dir-marker      

  bus_putchar1(gc#a_SDDMSET)
  bus_putchar1(marker)

PUB sddmget(marker):status                              'sd-card: dir-marker abfragen
''funktionsgruppe               : sdcard
''funktion                      : den status eines ausgewählter dir-marker abfragen
''busprotokoll                  : [027][put.dmarker][sub_getlong.dmstatus]
''                              : dmarker  - dir-marker     
''                              : dmstatus - status des markers

  bus_putchar1(gc#a_SDDMGET)
  bus_putchar1(marker)
  status := bus_getlong1
  
PUB sddmclr(marker)                                     'sd-card: dir-marker löschen
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker löschen
''busprotokoll                  : [028][put.dmarker]
''                              : dmarker - dir-marker      

  bus_putchar1(gc#a_SDDMCLR)
  bus_putchar1(marker)

PUB sddmput(marker,status)                              'sd-card: dir-marker status setzen
''funktionsgruppe               : sdcard
''funktion                      : dir-marker status setzen
''busprotokoll                  : [027][put.dmarker][sub_putlong.dmstatus]
''                              : dmarker  - dir-marker
''                              : dmstatus - status des markers

  bus_putchar1(gc#a_SDDMPUT)
  bus_putchar1(marker)
  bus_putlong1(status)

con'--------------------------------------------------- DCF77-Funktionen --------------------------------------------------------------------------------------------------------
{pub dcf_sync:on
    bus_putchar1(gc#a_DCF_INSYNC)
    on:=bus_getchar1

pub dcf_update
    bus_putchar1(gc#a_DCF_UPDATE_CLOCK)

pub dcf_geterror:on
    bus_putchar1(gc#a_DCF_GETBITERROR)
    on:=bus_getchar1
pub dcf_getdatacount:on
    bus_putchar1(gc#a_DCF_GETDatacount)
    on:=bus_getchar1
pub dcf_getbitnumber:on
    bus_putchar1(gc#a_DCF_GetBitNumber)
    on:=bus_getchar1
pub dcf_getbitlevel:on
    bus_putchar1(gc#a_DCF_GetBitLevel)
    on:=bus_getchar1
pub dcf_gettimezone:on
    bus_putchar1(gc#a_DCF_GetTimeZone)
    on:=bus_getchar1
pub dcf_getactive:on
    bus_putchar1(gc#a_DCF_GetActiveSet)
    on:=bus_getchar1
pub dcf_startup
    bus_putchar1(gc#a_DCF_start)

pub dcf_down
    bus_putchar1(gc#a_DCF_stop)

pub dcf_status:on
    bus_putchar1(gc#a_DCF_dcfon)
    on:=bus_getchar1

pub dcf_getseconds:on
    bus_putchar1(gc#a_DCF_Getseconds)
    on:=bus_getchar1
pub dcf_getminutes:on
    bus_putchar1(gc#a_DCF_GetMinutes)
    on:=bus_getchar1
pub dcf_gethours:on
    bus_putchar1(gc#a_DCF_Gethours)
    on:=bus_getchar1
pub dcf_getweekday:on
    bus_putchar1(gc#a_DCF_GetWeekDay)
    on:=bus_getchar1
pub dcf_getday:on
    bus_putchar1(gc#a_DCF_GetDay)
    on:=bus_getchar1
pub dcf_getmonth:on
    bus_putchar1(gc#a_DCF_GetMonth)
    on:=bus_getchar1
pub dcf_getyear:on
    bus_putchar1(gc#a_DCF_GetYear)
    on:=bus_getword1
    }
CON ''------------------------------------------------- I2C Slave
{pub i2c_adress|i
    bus_putchar1(gc#a_slaveadress)
    repeat i from 0 to 15
         register[i] := bus_getchar1
    return @register

pub i2c_readregister(a)

    return register[a]

pub i2c_put(a,b)
    bus_putchar1(gc#a_slaveput)
    bus_putchar1(a)
    bus_putchar1(b)

pub i2c_get(a):b
    bus_putchar1(gc#a_slaveget)
    bus_putchar1(a)
    b:=bus_getchar1

pub i2c_flush
    bus_putchar1(gc#a_slaveflush)

pub i2c_isDone|a
    bus_putchar1(gc#a_slavedone)
    return bus_getchar1


pub i2c_ClearDone

    bus_putchar1(gc#a_slavecleardone)

pub i2c_CheckRegister(n)|a
    bus_putchar1(gc#a_Checkregister)
    bus_putchar1(n)
    a:=bus_getlong1
    return a
}
CON ''------------------------------------------------- DATE TIME FUNKTIONEN
pub time(x,y)|h,m,s
    setpos(y,x)
    s:=getSeconds
   if s<>tmptime
      h:=gethours
      m:=getMinutes
        if h<10
           printchar("0")
        printdec(h)
        printchar(":")
        if m<10
           printchar("0")
        printdec(m)
        printchar(":")
        if s<10
           printchar("0")
        printdec(s)
        tmptime:=s

PUB getSeconds                                          'Returns the current second (0 - 59) from the real time clock.
  bus_putchar1(gc#a_rtcGetSeconds)
  return bus_getlong1

PUB getMinutes                                          'Returns the current minute (0 - 59) from the real time clock.
  bus_putchar1(gc#a_rtcGetMinutes)
  return bus_getlong1

PUB getHours                                            'Returns the current hour (0 - 23) from the real time clock.
  bus_putchar1(gc#a_rtcGetHours)
  return bus_getlong1

PUB getDay                                              'Returns the current day (1 - 7) from the real time clock.
  bus_putchar1(gc#a_rtcGetDay)
  return bus_getlong1

PUB getDate                                             'Returns the current date (1 - 31) from the real time clock.
  bus_putchar1(gc#a_rtcGetDate)
  return bus_getlong1

PUB getMonth                                            'Returns the current month (1 - 12) from the real time clock.
  bus_putchar1(gc#a_rtcGetMonth)
  return bus_getlong1

PUB getYear                                             'Returns the current year (2000 - 2099) from the real time clock.
  bus_putchar1(gc#a_rtcGetYear)
  return bus_getlong1

PUB setSeconds(seconds)                                 'Sets the current real time clock seconds.
                                                        'seconds - Number to set the seconds to between 0 - 59.
  if seconds => 0 and seconds =< 59
    bus_putchar1(gc#a_rtcSetSeconds)
    bus_putlong1(seconds)

PUB setMinutes(minutes)                                 'Sets the current real time clock minutes.
                                                        'minutes - Number to set the minutes to between 0 - 59.
  if minutes => 0 and minutes =< 59
    bus_putchar1(gc#a_rtcSetMinutes)
    bus_putlong1(minutes)

PUB setHours(hours)                                     'Sets the current real time clock hours.
                                                        'hours - Number to set the hours to between 0 - 23.

  if hours => 0 and hours =< 23
    bus_putchar1(gc#a_rtcSetHours)
    bus_putlong1(hours)

PUB setDay(day)                                         'Sets the current real time clock day.
                                                        'day - Number to set the day to between 1 - 7.
  if day => 1 and day =< 7
    bus_putchar1(gc#a_rtcSetDay)
    bus_putlong1(day)

PUB setDate(date)                                       'Sets the current real time clock date.
                                                        'date - Number to set the date to between 1 - 31.
  if date => 1 and date =< 31
    bus_putchar1(gc#a_rtcSetDate)
    bus_putlong1(date)

PUB setMonth(month)                                     'Sets the current real time clock month.
                                                        'month - Number to set the month to between 1 - 12.
  if month => 1 and month =< 12
    bus_putchar1(gc#a_rtcSetMonth)
    bus_putlong1(month)

PUB setYear(year)                                       'Sets the current real time clock year.
                                                        'year - Number to set the year to between 2000 - 2099.
  if year => 2000 and year =< 2099
    bus_putchar1(gc#a_rtcSetYear)
    bus_putlong1(year)

PUB setNVSRAM(index, value)                             'Sets the NVSRAM to the selected value (0 - 255) at the index (0 - 55).
                                                        'index - The location in NVRAM to set (0 - 55).
                                                        'value - The value (0 - 255) to change the location to.
  if index => 0 AND index =< 55 AND value => 0 AND value =< 255
    bus_putchar1(gc#a_rtcSetNVSRAM)
    bus_putlong1(index)
    bus_putlong1(value)

PUB getNVSRAM(index)                                    'Gets the selected NVSRAM value at the index (0 - 55).
                                                        'Returns the selected location's value (0 - 255).
                                                        'index - The location in NVRAM to get (0 - 55).
  bus_putchar1(gc#a_rtcGetNVSRAM)
  bus_putlong1(index)
  return bus_getlong1
{
PUB pauseForSeconds(number)                             'Pauses execution for a number of seconds.
                                                        'number - Number of seconds to pause for between 0 and 2,147,483,647.
  bus_putchar1(gc#a_rtcPauseForSec)
  return bus_getlong1

PUB pauseForMilliseconds(number)                        'Pauses execution for a number of milliseconds.
                                                        'Returns a puesdo random value derived from the current clock frequency and the time when called.
                                                        'number - Number of milliseconds to pause for between 0 and 2,147,483,647.
  bus_putchar1(gc#a_rtcPauseForMSec)
  return bus_getlong1
}
con'--------------------------------------------------- AY-DMP-Player--------------------------------------------------------------------------------------------------------------
{PUB ay_sdmpplay(stradr): err                           'sid: dmp-datei stereo auf beiden sid's abspielen
''funktionsgruppe               : sid
''funktion                      : sid: dmp-datei stereo auf beiden sid's abspielen
''busprotokoll                  : [158][sub.putstr][get.err]
''                              : err - fehlernummer entspr. liste

  bus_putchar1(AYCOG_SDMPPLAY)
  bus_putstr1(stradr)
  err := bus_getchar1
}
CON ''------------------------------------------------- SIDCog DMP-Player

'PUB sid_mdmpplay(stradr): err                           'sid: dmp-datei mono auf sid2 abspielen
''funktionsgruppe               : sid
''funktion                      : dmp-datei auf sid2 von sd-card abspielen
''busprotokoll                  : [157][sub.putstr][get.err]
''                              : err - fehlernummer entspr. liste

'  bus_putchar1(SCOG_MDMPPLAY)
'  bus_putstr1(stradr)
'  err := bus_getchar1

PUB sid_sdmpplay(stradr): err                           'sid: dmp-datei stereo auf beiden sid's abspielen
''funktionsgruppe               : sid
''funktion                      : sid: dmp-datei stereo auf beiden sid's abspielen
''busprotokoll                  : [158][sub.putstr][get.err]
''                              : err - fehlernummer entspr. liste

  bus_putchar1(gc#a_s_sdmpplay)
  bus_putstr1(stradr)
  err := bus_getchar1

PUB sid_dmpstop
  bus_putchar1(gc#a_s_dmpstop)

PUB sid_dmppause
  bus_putchar1(gc#a_s_dmppause)

PUB sid_dmpstatus: status
  bus_putchar1(gc#a_s_dmpstatus)
  status := bus_getchar1

PUB sid_dmppos: wert
  bus_putchar1(gc#a_s_dmppos)
  wert := bus_getlong1


PUB sid_dmplen: wert
  bus_putchar1(gc#a_s_dmplen)
         ' bus_getlong1
  wert := bus_getlong1

PUB sid_mute(sidnr)                                     'sid: chips stummschalten
  bus_putchar1(gc#a_s_mute)
  bus_putchar1(sidnr)

pub sid_resetRegisters
  bus_putchar1(196)
  bus_putchar1(197)

PUB sid_dmpreg: stradr | i                              'sid: dmp-register empfangen
' daten im puffer
' word  frequenz kanal 1
' word  frequenz kanal 2
' word  frequenz kanal 3
' byte  volume

  i := 0
  bus_putchar1(199)
  repeat 7
    byte[@strpuffer + i++] := bus_getchar1
  return @strpuffer
CON ''------------------------------------------------- SIDCog1-Funktionen

PUB sid1_setRegister(reg,val)
  bus_putchar1(gc#a_s1_setRegister)
  bus_putchar1(reg)
  bus_putchar1(val)

PUB sid1_updateRegisters(regadr)
  bus_putchar1(gc#a_s1_updateRegisters)
  repeat 25
    bus_putchar1(byte[regadr++])

PUB sid1_setVolume(vol)
  bus_putchar1(gc#a_s1_setVolume)
  bus_putchar1(vol)

PUB sid1_play(channel, freq, waveform, attack, decay, sustain, release)
  bus_putchar1(gc#a_s1_play)
  bus_putchar1(channel)
  bus_putchar1(freq)
  bus_putchar1(waveform)
  bus_putchar1(attack)
  bus_putchar1(decay)
  bus_putchar1(sustain)
  bus_putchar1(release)

PUB sid1_noteOn(channel, freq)
  bus_putchar1(gc#a_s1_noteOn)
  bus_putchar1(channel)
  bus_putchar1(freq)
  'bus_putlong1(freq)

PUB sid1_noteOff(channel)
  bus_putchar1(gc#a_s1_noteOff)
  bus_putchar1(channel)

PUB sid1_setFreq(channel,freq)
  bus_putchar1(gc#a_s1_setFreq)
  bus_putchar1(channel)
  bus_putlong1(freq)

PUB sid1_setWaveform(channel,waveform)
  bus_putchar1(gc#a_s1_setWaveform)
  bus_putchar1(channel)
  bus_putchar1(waveform)

PUB sid1_setPWM(channel, val)
  bus_putchar1(gc#a_s1_setPWM)
  bus_putchar1(channel)
  bus_putlong1(val)

PUB sid1_setADSR(channel, attack, decay, sustain, release )
  bus_putchar1(gc#a_s1_setADSR)
  bus_putchar1(channel)
  bus_putchar1(attack)
  bus_putchar1(decay)
  bus_putchar1(sustain)
  bus_putchar1(release)

PUB sid1_setResonance(val)
  bus_putchar1(gc#a_s1_setResonance)
  bus_putchar1(val)

PUB sid1_setCutoff(freq)
  bus_putchar1(gc#a_s1_setCutoff)
  bus_putlong1(freq)

PUB sid1_setFilterMask(ch1,ch2,ch3)
  bus_putchar1(gc#a_s1_setFilterMask)
  bus_putchar1(ch1)
  bus_putchar1(ch2)
  bus_putchar1(ch3)

PUB sid1_setFilterType(lp,bp,hp)
  bus_putchar1(gc#a_s1_setFilterType)
  bus_putchar1(lp)
  bus_putchar1(bp)
  bus_putchar1(hp)

PUB sid1_enableRingmod(ch1,ch2,ch3)
  bus_putchar1(gc#a_s1_enableRingmod)
  bus_putchar1(ch1)
  bus_putchar1(ch2)
  bus_putchar1(ch3)

PUB sid1_enableSynchronization(ch1,ch2,ch3)
  bus_putchar1(gc#a_s1_enableSynchronization)
  bus_putchar1(ch1)
  bus_putchar1(ch2)
  bus_putchar1(ch3)

pub sid_beep(n)
  bus_putchar1(198)
  bus_putchar1(n)


OBJ '' B E L L A T R I X

CON ''------------------------------------------------- CHIP-MANAGMENT

PUB belgetcogs:belcogs                                  'chip-mgr: verwendete cogs abfragen

  bus_putchar2(BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(BMGR_GETCOGS)                            'code 5 = freie cogs
  belcogs := bus_getchar2                               'statuswert empfangen
pub bel_get:vers
  bus_putchar2(BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(BMGR_GETVER)                             'code 95 = tiledriver 64 farben
  vers := bus_getlong2                                  'statuswert empfangen

PUB belgetspec:spec                                     'chip-mgr: spezifikationen abfragen
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''busprotokoll                  : [089][sub_getlong.spec]
''                              : spec - spezifikation
''
''
''                                          +----------
''                                          | +--------
''                                          | |+------- vektor
''                                          | ||+------ grafik
''                                          | |||+----- text
''                                          | ||||+---- maus
''                                          | |||||+--- tastatur
''                                          | ||||||+-- vga
''                                          | |||||||+- tv
''spezifikation = %00000000_00000000_00000000_00010110

  bus_putchar2(BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(BMGR_GETSPEC)
  spec := bus_getlong2

PUB belreset                                            'chip-mgr: bellatrix reset
{{breset - bellatrix neu starten}}

  bus_putchar2(BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(BMGR_REBOOT)                             'code 99 = reboot

PUB belload(stradr)                                     'chip-mgr: neuen bellatrix-code booten

  bus_putchar2(BEL_CMD)                                 'kommandosequenz einleiten
  bus_putchar2(BMGR_LOAD)                               'code 87 = code laden
  waitcnt(cnt + 2_000_000)                              'warte bis bel fertig ist
  bload(stradr)
  waitcnt(cnt + 2_000_000)                              'warte bis bel fertig ist

PUB bload(stradr) | n,rc,ii,plen                        'system: bellatrix mit grafiktreiber initialisieren
{{bload(stradr) - bellatrix mit grafiktreiber initialisieren
  wird zusätzlich zu belload gebraucht, da situationen auftreten, in denen bella ohne reset (kaltstart) mit
  einem treiber versorgt werden muß. ist der bella-loader aktiv, reagiert er nicht auf das reset-kommando.
  stradr  - adresse eines 0-term-strings mit dem dateinamen des bellatrixtreibers
}}

' kopf der bin-datei einlesen                           ------------------------------------------------------
  rc := sdopen("r",stradr)                              'datei öffnen
  repeat ii from 0 to 15                                '16 bytes header --> bellatrix
    n := sdgetc
    bus_putchar2(n)
  sdclose                                               'bin-datei schießen

' objektgröße empfangen
  plen := bus_getchar2 << 8                             'hsb empfangen
  plen := plen + bus_getchar2                           'lsb empfangen

' bin-datei einlesen                                    ------------------------------------------------------
  sdopen("r",stradr)                                    'bin-datei öffnen
  repeat ii from 0 to plen-1                            'datei --> bellatrix
    n := sdgetc
    bus_putchar2(n)
  sdclose


CON ''------------------------------------------------- KEYBOARD

PUB key:wert                                            'key: holt tastaturcode
{{key:wert - key: übergibt tastaturwert}}
  bus_putchar2($0)              'kommandosequenz einleiten
  bus_putchar2($2)              'code 2 = tastenwert holen
  wert := bus_getword2          'tastenwert empfangen

PUB keyspec:wert                                        'key: statustasten zum letzten tastencode
  bus_putchar2($0)              'kommandosequenz einleiten
  bus_putchar2($4)              'code 2 = tastenwert holen
  wert := bus_getchar2          'wert empfangen


PUB keystat:status                                      'key: übergibt tastaturstatus
{{keystat:status - key: übergibt tastaturstatus}}
  bus_putchar2($0)              'kommandosequenz einleiten
  bus_putchar2($1)              'code 1 = tastaturstatus
  status := bus_getchar2        'statuswert empfangen

PUB keywait:n                                           'key: wartet bis taste gedrückt wird
{{keywait: n - key: wartet bis eine taste gedrückt wurde}}
  repeat
  until keystat > 0
  return key

pub inkey:n
  bus_putchar2($0)              'kommandosequenz einleiten
  bus_putchar2($7)              'code 2 = tastenwert holen
  n := bus_getchar2             'wert empfangen

pub clearkey
  bus_putchar2($0)
  bus_putchar2($D)
con ''------------------------------------------------- Mode2-Funktionen ---------------------------------------------------------------------------------------------------------
pub ChangeColor(v,h)
    bus_putchar2(BEL_CMD)
    bus_putchar2(mode2_color)
    bus_putchar2(v)
    bus_putchar2(h)
pub ChangeColor2(c3,c4)
    bus_putchar2(BEL_CMD)
    bus_putchar2(mode6_color)
    bus_putchar2(c3)
    bus_putchar2(c4)

pub petkeyboardright
    bus_putchar2(BEL_CMD)
    bus_putchar2(petright)

pub cls
    bus_putchar2(BEL_CMD)
    bus_putchar2(12)

pub petkeyboardleft
    bus_putchar2(BEL_CMD)
    bus_putchar2(petleft)

pub plotxy(x,y,n)
    bus_putchar2(BEL_CMD)
    bus_putchar2(plot)
    bus_putword2(x)
    bus_putword2(y)
    bus_putchar2(n)

pub Cursoron
    bus_putchar2(BEL_CMD)
    bus_putchar2(Cursor_On)

pub Cursoroff
    bus_putchar2(BEL_CMD)
    bus_putchar2(Cursor_Off)

pub setxy_2(x,y)
    bus_putchar2(BEL_CMD)
    bus_putchar2(c_set)
    bus_putchar2(x)
    bus_putchar2(y)
    'bus_putchar2(c)

pub getxy(x,y):c
    bus_putchar2(BEL_CMD)
    bus_putchar2(c_get)
    bus_putchar2(x)
    bus_putchar2(y)
    c:=bus_getchar2

pub box_2(x0, y0, x1, y1,n)
    bus_putchar2(BEL_CMD)
    bus_putchar2(36)
    bus_putword2(x0)
    bus_putword2(y0)
    bus_putword2(x1)
    bus_putword2(y1)
    bus_putchar2(n)

pub line_2(x0, y0, x1, y1,n)
    bus_putchar2(BEL_CMD)
    bus_putchar2(35)
    bus_putword2(x0)
    bus_putword2(y0)
    bus_putword2(x1)
    bus_putword2(y1)
    bus_putchar2(n)
pub circ_2(x,y,r1,r2,n)
    bus_putchar2(BEL_CMD)
    bus_putchar2(37)
    bus_putword2(x)
    bus_putword2(y)
    bus_putword2(r1)
    bus_putword2(r2)
    bus_putchar2(n)
{pub textcolor(c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(text_color)
    bus_putchar2(c)

pub backcolor(c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(back_color)
    bus_putchar2(c)
    }
con ''------------------------------------------------- Mode3-Funktionen ---------------------------------------------------------------------------------------------------------

pub redefine_3(c,c0,c1,c2,c3,c4,c5,c6,c7)
    bus_putchar2(BEL_CMD)
    bus_putchar2(200)
    bus_putchar2(c)
    bus_putchar2(c0)
    bus_putchar2(c1)
    bus_putchar2(c2)
    bus_putchar2(c3)
    bus_putchar2(c4)
    bus_putchar2(c5)
    bus_putchar2(c6)
    bus_putchar2(c7)

pub plot_3(x,y,c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(201)
    bus_putword2(x)
    bus_putword2(y)
    bus_putchar2(c)

pub line_3(x0, y0, x1, y1, c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(202)
    bus_putchar2(x0)
    bus_putchar2(y0)
    bus_putchar2(x1)
    bus_putchar2(y1)
    bus_putchar2(c)

pub box_3(x0, y0, x1, y1, c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(203)
    bus_putchar2(x0)
    bus_putchar2(y0)
    bus_putchar2(x1)
    bus_putchar2(y1)
    bus_putchar2(c)

pub addsprite_3(n)
    bus_putchar2(BEL_CMD)
    bus_putchar2(209)
    bus_putchar2(n)

pub setsprite_3(a,b,c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(210)
    bus_putchar2(a)
    bus_putchar2(b)
    bus_putchar2(c)


pub video_peek_3(a,b)|c
    bus_putchar2(BEL_CMD)
    bus_putchar2(211)
    bus_putchar2(a)
    bus_putchar2(b)
    c:=bus_getchar2
    return c
con ''------------------------------------------------- Mode5-Funktionen ---------------------------------------------------------------------------------------------------------

pub cur_off
    bus_putchar2(BEL_CMD)
    bus_putchar2(21)

pub cur_on
    bus_putchar2(BEL_CMD)
    bus_putchar2(22)
con'''------------------------------------------------- Mode4-Funktionen ---------------------------------------------------------------------------------------------------------
pub sprite_palette(a,b)
    bus_putchar2(BEL_CMD)
    bus_putchar2(20)
    bus_putchar2(a)
    bus_putchar2(b)

pub Longsprite(a,b)
    bus_putchar2(BEL_CMD)
    bus_putchar2(21)
    bus_putlong2(a)
    bus_putlong2(b)

pub Longtiles(a,b)
    bus_putchar2(BEL_CMD)
    bus_putchar2(22)
    bus_putlong2(a)
    bus_putlong2(b)


pub render_set_backround_origin(a,b)
    bus_putchar2(BEL_CMD)
    bus_putchar2(23)
    bus_putchar2(a)
    bus_putchar2(b)

pub write_byte_at(x,y,palette,text)
    bus_putchar2(BEL_CMD)
    bus_putchar2(24)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(palette)
    bus_putchar2(text)
pub reset_sprites
    bus_putchar2(BEL_CMD)
    bus_putchar2(25)
pub Animate(sp, st, en, dl)
    bus_putchar2(BEL_CMD)
    bus_putchar2(26)
    bus_putchar2(sp)
    bus_putchar2(st)
    bus_putchar2(en)
    bus_putchar2(dl)
pub MoveSpeed(sp, xdly, ydly, xi, yi)
    bus_putchar2(BEL_CMD)
    bus_putchar2(27)
    bus_putchar2(sp)
    bus_putchar2(xdly)
    bus_putchar2(ydly)
    bus_putchar2(xi)
    bus_putchar2(yi)

pub SetSprPos(sp, xp, yp)
    bus_putchar2(BEL_CMD)
    bus_putchar2(28)
    bus_putchar2(sp)
    bus_putchar2(xp)
    bus_putchar2(yp)

pub PaletteColorDef(a,b,c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(29)
    bus_putchar2(a)
    bus_putchar2(b)
    bus_putchar2(c)

pub LoadSpr(si,st,sx,sy,mr,sp)
    bus_putchar2(BEL_CMD)
    bus_putchar2(30)
    bus_putchar2(si)
    bus_putchar2(st)
    bus_putchar2(sx)
    bus_putchar2(sy)
    bus_putchar2(mr)
    bus_putchar2(sp)

pub render_sprite_hide(n)
    bus_putchar2(BEL_CMD)
    bus_putchar2(31)
    bus_putchar2(n)
pub render_sprite_move(a,b,c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(33)
    bus_putchar2(a)
    bus_putchar2(b)
    bus_putchar2(c)

pub get_sprattr(a)|b
    bus_putchar2(BEL_CMD)
    bus_putchar2(34)
    bus_putchar2(a)
    b:=bus_getchar2
    return b

pub render_sprite_image(i,c)
    bus_putchar2(BEL_CMD)
    bus_putchar2(35)
    bus_putchar2(i)
    bus_putchar2(c)
CON ''------------------------------------------------- SCREEN
'var byte globalcolor 'gesetzte hintergrundfarbe
PUB print(stringptr)|c                                    'screen: bildschirmausgabe einer zeichenkette (0-terminiert)
{{print(stringptr) - screen: bildschirmausgabe einer zeichenkette (0-terminiert)}}
  repeat strsize(stringptr)
    c:=byte[stringptr++]
    bus_putchar2(c)

pub get_window:a
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_Get_Window)
    a:=bus_getchar2

pub windel(num)|i,c
    i:=$7E500
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_Del_Window)
    bus_putchar2(num)
    repeat 17
         c:=ram_rdbyte(i++)
         bus_putchar2(c)

pub window(win,farbe1,farbe2,farbe3,farbe4,farbe5,farbe6,farbe7,farbe8,y,x,yy,xx,modus,shd)',frm)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_Window)
    bus_putchar2(win)
    bus_putchar2(farbe1)
    bus_putchar2(farbe2)
    bus_putchar2(farbe3)
    bus_putchar2(farbe4)
    bus_putchar2(farbe5)
    bus_putchar2(farbe6)
    bus_putchar2(farbe7)
    bus_putchar2(farbe8)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(modus)
    bus_putchar2(shd)

pub printfont(win,str,f1,f2,f3,y,x,offset)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_PRINTFONT)
    bus_putchar2(win)
    bus_putchar2(f1)
    bus_putchar2(f2)
    bus_putchar2(f3)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(offset)
    bus_putstr2(str)

pub Set_Titel_Status(win,modus,char)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SET_TITELSTATUS)
    bus_putchar2(win)       'Fensternummer
    bus_putchar2(modus)     'titel oder statustext
    bus_putstr2(char)       'String

pub printBoxSize(win,y, x,yy, xx)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_BoxSize)
    bus_putchar2(win)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
pub printwindow(win) 'wieder hauptfenster setzen
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_WIN)
    bus_putchar2(win)
pub printBoxColor(win,vor, hinter,cursor)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_BOXCOLOR)
    bus_putchar2(win)
    bus_putchar2(vor)
    bus_putchar2(hinter)
    bus_putchar2(cursor)

pub printCursorRate(rate)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_CursorRate)
    bus_putchar2(rate)

pub display2dbox(farbe, y, x, yy, xx,shd)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_2DBOX)
    bus_putchar2(farbe)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(shd)

pub scrollup(lines, farbe, y, x, yy, xx,rate)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SCOLLUP)
    bus_putchar2(lines)
    bus_putchar2(farbe)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(rate)

pub scrolldown(lines, farbe, y, x, yy, xx,rate)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SCOLLDOWN)
    bus_putchar2(lines)
    bus_putchar2(farbe)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)
    bus_putchar2(rate)

pub display3DBox(topColor, centerColor, bottomColor, y, x, yy, xx)

    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_3DBOX)
    bus_putchar2(topColor)
    bus_putchar2(centerColor)
    bus_putchar2(bottomColor)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)

pub display3DFrame(topColor, centerColor, bottomColor, y, x, yy, xx)

    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_3DFRAME)
    bus_putchar2(topColor)
    bus_putchar2(centerColor)
    bus_putchar2(bottomColor)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(yy)
    bus_putchar2(xx)

pub send_button_param(number,x,y,xx)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_Send_BUTTON)
    bus_putchar2(number)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)

pub destroy3dbutton(number)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_ERS_3DBUTTON)
    bus_putchar2(number)

pub Plot_Line(x, y, xx, yy,farbe)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_LINE)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)
    bus_putchar2(yy)
    bus_putchar2(farbe)

pub PlotPixel(farbe,x,y)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_PIXEL)
    bus_putchar2(farbe)
    bus_putchar2(y)
    bus_putchar2(x)
pub Actorset(tnr1,col1,col2,col3,x,y)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_ACTOR)
    bus_putchar2(tnr1)
    bus_putchar2(col1)
    bus_putchar2(col2)
    bus_putchar2(col3)
    bus_putchar2(x)
    bus_putchar2(y)
pub setactor_xy(k)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_ACTORPOS)
    bus_putchar2(k)
    'bus_putchar2(y)
pub setactionkey(k1,k2,k3,k4,k5)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_ACT_KEY)
    bus_putchar2(k1)
    bus_putchar2(k2)
    bus_putchar2(k3)
    bus_putchar2(k4)
    bus_putchar2(k5)
pub reset_sprite
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SPRITE_RESET)
    
pub set_sprite(num,tnr,tnr2,f1,f2,f3,dir,strt,end,x,y)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SPRITE_PARAM)
    bus_putchar2(num)
    bus_putchar2(tnr)        'tilenrnummer
    bus_putchar2(tnr2)       'tilenrnummer2
    bus_putchar2(f1)         'farben 1-3
    bus_putchar2(f2)
    bus_putchar2(f3)
    bus_putchar2(dir)        'richtung
    bus_putchar2(strt)      'startposition
    bus_putchar2(end)        'endposition
    bus_putchar2(x)          'x und y parameter
    bus_putchar2(y) 

    
pub Sprite_Move(on)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SPRITE_MOVE)
    bus_putchar2(on)
pub set_sprite_speed(wert)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SPRITE_SPEED)
    bus_putchar2(wert)
pub get_Collision
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_GET_COLLISION)
    return bus_getchar2
pub get_actor_pos(n)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_GET_ACTOR_POS)
    bus_putchar2(n)
    return bus_getchar2
pub send_block(n,tnr)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SEND_BLOCK)
    bus_putchar2(n)
    bus_putchar2(tnr)
pub Change_Backuptile(tnr,f1,f2,f3)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_CHANGE_BACKUP)
    bus_putchar2(tnr)
    bus_putchar2(f1)
    bus_putchar2(f2)
    bus_putchar2(f3)

pub displayString(char,foregroundColor, backgroundColor, y, x)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_STRING)
    bus_putchar2(foregroundColor)
    bus_putchar2(backgroundColor)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putstr2(char)

pub scrollString(str,characterRate, foregroundColor, backgroundColor, y, x, xx)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SCROLLSTRING)
    bus_putchar2(characterRate)
    bus_putchar2(foregroundColor)
    bus_putchar2(backgroundColor)
    bus_putchar2(y)
    bus_putchar2(x)
    bus_putchar2(xx)
    bus_putstr2(str)



pub setpos(y,x)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_SETPOS)
    bus_putchar2(y)
    bus_putchar2(x)
pub setx(x)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_SETX)
    bus_putchar2(x)
pub sety(y)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_SETY)
    bus_putchar2(y)

pub displayTile(tnr,pcol,scol,tcol, row, column)

                bus_putchar2(BEL_CMD)
                bus_putchar2(BEL_DPL_TILE)
                bus_putchar2(tnr)
                bus_putchar2(pcol)
                bus_putchar2(scol)
                bus_putchar2(tcol)
                bus_putchar2(row)
                bus_putchar2(column)

pub Mousepointer(adr)|c
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_LD_MOUSEPOINTER)

    repeat 16
          c:=ram_rdlong(adr)
          bus_putlong2(c)
          adr+=4
pub mousebound(x,y,xx,yy)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_LD_MOUSEBOUND)
    bus_putlong2(x)
    bus_putlong2(y)
    bus_putlong2(xx)
    bus_putlong2(yy)

pub loadtilebuffer(adr,anzahl)|c
          bus_putchar2(BEL_CMD)
          bus_putchar2(BEL_LD_TILESET)
          bus_putlong2(anzahl)

          repeat anzahl
                  c:=ram_rdlong(adr)
                  bus_putlong2(c)
                  adr+=4
pub displaypic(pcol,scol,tcol,y,x,ytile,xtile)
                bus_putchar2(BEL_CMD)
                bus_putchar2(BEL_DPL_PIC)
                bus_putchar2(pcol)
                bus_putchar2(scol)
                bus_putchar2(tcol)
                bus_putchar2(y)
                bus_putchar2(x)
                bus_putchar2(ytile)
                bus_putchar2(xtile)

pub getx |x
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_GETX)
    x:=bus_getchar2
    return x
pub gety |y
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_GETY)
    y:=bus_getchar2
    return y

pub DisplayMouse(on,color)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_MOUSE)
    bus_putchar2(on)
    bus_putchar2(color)
pub Displaypalette(x,y)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_DPL_PALETTE)
    bus_putchar2(x)
    bus_putchar2(y)

{pub cls
    printchar(12)
}
pub Backup_Area(x,y,xx,yy,adr)|a,b,d
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_BACK)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)
    bus_putchar2(yy)
    repeat a from y to yy
        repeat b from x to xx
           d:=bus_getlong2
           ram_wrlong(d,adr)
           adr+=4
           ram_wrword(bus_getword2,adr)
           adr+=2

pub restore_Area(x,y,xx,yy,adr)|a,b
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_REST)
    bus_putchar2(x)
    bus_putchar2(y)
    bus_putchar2(xx)
    bus_putchar2(yy)
    repeat a from y to yy
          repeat b from x to xx
                bus_putlong2(ram_rdlong(adr))
                adr+=4
                bus_putword2(ram_rdword(adr))
                adr+=2

PUB printq(stringptr)                                   'screen: zeichenkette ohne steuerzeichen (0-terminiert)
{{print(stringptr) - screen: bildschirmausgabe einer zeichenkette (0-terminiert)}}
  repeat strsize(stringptr)
    bus_putchar2(BEL_CMD)
    bus_putchar2(BEL_SCR_CHAR)
    bus_putchar2(byte[stringptr])
    'if serial==1
    '   ser.tx(byte[stringptr++])
{PUB printcstr(eadr) | i,len                             'screen: bildschirmausgabe einer zeichenkette im eram! (mit längenbyte)
{{printcstr(eadr) - screen: bildschirmausgabe einer zeichenkette im eram (mit längenbyte)}}
  len := ram_rdbyte(1,eadr)
  repeat i from 1 to len
    eadr++
    bus_putchar2(ram_rdbyte(1,eadr))
}
PUB printdec(value) | i ,c ,x                             'screen: dezimalen zahlenwert auf bildschirm ausgeben
{{printdec(value) - screen: dezimale bildschirmausgabe zahlenwertes}}
  if value < 0                                          'negativer zahlenwert
    -value
    printchar("-")

  i := 1_000_000_000
  repeat 10                                             'zahl zerlegen
    if value => i
      x:=value / i + "0"
      printchar(x)
      c:=value / i + "0"
      value //= i
      result~~
    elseif result or i == 1
      printchar("0")
    i /= 10                                             'nächste stelle

PUB printhex(value, digits)                             'screen: hexadezimalen zahlenwert auf bildschirm ausgeben
{{hex(value,digits) - screen: hexadezimale bildschirmausgabe eines zahlenwertes}}
  value <<= (8 - digits) << 2
  repeat digits
    printchar(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB printbin(value, digits) |c                            'screen: binären zahlenwert auf bildschirm ausgeben

  value <<= 32 - digits
  repeat digits
     c:=(value <-= 1) & 1 + "0"
     printchar(c)

PUB printchar(c)':c2                                     'screen: einzelnes zeichen auf bildschirm ausgeben
{{printchar(c) - screen: bildschirmausgabe eines zeichens}}
  bus_putchar2(c)

PUB printqchar(c)':c2                                    'screen: zeichen ohne steuerzeichen ausgeben
{{printqchar(c) - screen: bildschirmausgabe eines zeichens}}
  bus_putchar2(BEL_CMD)
  bus_putchar2(BEL_SCR_CHAR)
  bus_putchar2(c)
'  c2 := c
  'if serial==1
  '     ser.tx(c)
PUB printnl                                             'screen: $0D - CR ausgeben
{{printnl - screen: $0D - CR ausgeben}}
  bus_putchar2(CHAR_NL)
  'if serial==1
  '     ser.tx($0D)
  '     ser.tx($0A)

PUB printcls                                            'screen: screen löschen
{{printcls - screen: screen löschen}}
  printchar(12)

PUB printbs                                             'screen: backspace
{{curon - screen: backspace senden}}
  printchar(BEL_BS)

pub printleft
    printchar(5)
pub printright
    printchar(6)
pub mousex
  bus_putchar2(BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(BEL_MOUSEX)       'MOUSE-X-Position abfragen
  return bus_getchar2
pub mousey
  bus_putchar2(BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(BEL_MOUSEY)       'MOUSE-Y-Position abfragen

  return bus_getchar2                     'y-signal invertieren sonst geht der Mauszeiger hoch, wenn man runterscrollt

pub mousez
  bus_putchar2(BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(BEL_MOUSEZ)       'MOUSE-Z-Position abfragen
  return bus_getlong2

pub mouse_button(b)
  bus_putchar2(BEL_CMD)         'kommandosequenz einleiten
  bus_putchar2(BEL_MOUSE_BUTTON)       'MOUSE-Button abfragen
  bus_putchar2(b)
  return bus_getchar2

CON ''------------------------------------------------- Plexbus und Gamedevices

PUB plxrun                                              'plx: bus freigeben, poller starten

  bus_putchar1(gc#a_plxRun)

PUB plxhalt                                             'plx: bus anfordern, poller anhalten

  bus_putchar1(gc#a_plxHalt)

PUB plxin(adr):wert                                     'plx: port einlesen

  bus_putchar1(gc#a_plxIn)
  bus_putchar1(adr)
  wert := bus_getchar1

PUB plxout(adr,wert)                                    'plx: port ausgeben

  bus_putchar1(gc#a_plxOut)
  bus_putchar1(adr)
  bus_putchar1(wert)

PUB joy(chan):wert                                            'game: joystick abfragen

  bus_putchar1(gc#a_Joy)
  bus_putchar1(chan)
  wert := bus_getchar1

PUB paddle:wert                                         'game: paddle abfrage

  bus_putchar1(gc#a_Paddle)
  wert := wert + bus_getchar1 << 8
  wert := wert + bus_getchar1

PUB pad:wert                                            'game: pad abfrage

  bus_putchar1(gc#a_Pad)
  wert := wert + bus_getchar1 << 16
  wert := wert + bus_getchar1 << 8
  wert := wert + bus_getchar1

pub getreg(reg):wert
   bus_putchar1(gc#a_plxGetReg)
   bus_putchar1(reg)
   wert:=bus_getchar1

pub set_plxAdr(adda,Port)
   bus_putchar1(gc#a_plxSetAdr)                                     'adressen adda/ports für poller setzen
   bus_putchar1(adda)
   bus_putchar1(port)

pub plxping(adr):wert
   bus_putchar1(gc#a_plxPing)                                       'adressen adda/ports für poller setzen
   bus_putchar1(adr)
   wert:=bus_getchar1

pub plxstart
    bus_putchar1(gc#a_plxStart)                                     'I2C Start-Befehl

pub plxstop
    bus_putchar1(gc#a_plxStop)                                      'I2C Stop-Befehl

pub plxwrite(data):wert
    bus_putchar1(gc#a_plxWrite)                                     'I2C Write
    bus_putchar1(data)                                              'Daten
    wert:=bus_getchar1                                              'ack bit

pub plxread(ack):wert
    bus_putchar1(gc#a_plxRead)                                      'I2C Read
    bus_putchar1(ack)                                               'ack Bit
    wert:=bus_getchar1                                              'Rückgabewert

OBJ '' R E G N A T I X

CON ''------------------------------------------------- BUS
'prop 1  - administra   (bus_putchar1, bus_getchar1)
'prop 2  - bellatrix    (bus_putchar2, bus_getchar2)
'prop 3  - venatrix     (bus_putchar3, bus_getchar3)
PUB bus_init                                            'bus: initialisiert bussystem
{{bus_init - bus: initialisierung aller bussignale }}
  outa[bus_wr]    := 1          ' schreiben inaktiv
  outa[reg_ram1]  := 1          ' ram1 inaktiv
  outa[reg_ram2]  := 1          ' ram2 inaktiv
  outa[reg_prop1] := 1          ' prop1 inaktiv
  outa[reg_prop2] := 1          ' prop2 inaktiv
  outa[busclk]    := 0          ' busclk startwert
  outa[reg_al]    := 0          ' strobe aus
  dira := db_in                 ' datenbus auf eingabe schalten
  outa[18..8]     := 0          ' adresse a0..a10 auf 0 setzen
  outa[reg_al]    := 1 ' obere adresse in adresslatch übernehmen
  outa[reg_al]    := 0 ' und in Latch2 übernehmen (Sound auf Administra, VGA-on, RAM-Erweiterung auf Bellatrix)

  dira[reg_al2]   := 1
  outa[reg_al2]   := 1
  outa[reg_al2]   := 0
  dira[reg_al2]   := 0


PUB bus_getword1: wert                                  'bus: 16 bit von administra empfangen hsb/lsb

  wert := bus_getchar1 << 8
  wert := wert + bus_getchar1

PUB bus_putword1(wert)                                  'bus: 16 bit an administra senden hsb/lsb

   bus_putchar1(wert >> 8)
   bus_putchar1(wert)

PUB bus_getlong1: wert                                  'bus: long von administra empfangen hsb/lsb

  wert :=        bus_getchar1 << 24                     '32 bit empfangen hsb/lsb
  wert := wert + bus_getchar1 << 16
  wert := wert + bus_getchar1 << 8
  wert := wert + bus_getchar1

PUB bus_putlong1(wert)                                  'bus: long zu administra senden hsb/lsb

    repeat 4
       bus_putchar1(wert <-= 8)                            '32bit wert senden hsb/lsb

PUB bus_getstr1: stradr | len,i                         'bus: string von administra empfangen

    len  := bus_getchar1                                'längenbyte empfangen
    repeat i from 0 to len - 1                          '20 zeichen dateinamen empfangen
      strpuffer[i] := bus_getchar1
    strpuffer[i] := 0
    return @strpuffer

PUB bus_putstr1(stradr) | len,i                         'bus: string zu administra senden

  len := strsize(stradr)
  bus_putchar1(len)
  repeat i from 0 to len - 1
    bus_putchar1(byte[stradr++])

PUB bus_putstr2(stradr) | len,i                         'bus: string zu bellatrix senden

  len := strsize(stradr)
  bus_putchar2(len)
  repeat i from 0 to len - 1
    bus_putchar2(byte[stradr++])

PUB bus_getstr2: stradr | len,i                         'bus: string von administra empfangen

    len  := bus_getchar2                                'längenbyte empfangen
    repeat i from 0 to len - 1                          '20 zeichen dateinamen empfangen
      strpuffer[i] := bus_getchar2
    strpuffer[i] := 0
    return @strpuffer

PUB bus_putchar1(c)                                     'bus: byte an administra senden
{{bus_putchar1(c) - bus: byte senden an prop1 (administra)}}
 ' ram_rw.putchar1(c)
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa := %00000000_01011000_00000000_00000000          'prop1=0, wr=0
  outa[7..0] := c                                       'daten --> dbus
  outa[busclk] := 1                                     'busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  dira := db_in                                         'bus freigeben
  outa := %00001100_01111000_00000000_00000000           'wr=1, prop1=1, busclk=0

PUB bus_getchar1: wert                                  'bus: byte vom administra empfangen
{{bus_getchar1:wert - bus: byte empfangen von prop1 (administra)}}
'  wert:=ram_rw.getchar1
  outa := %00000110_01011000_00000000_00000000          'prop1=0, wr=1, busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  wert := ina[7..0]                                     'daten einlesen
  outa := %00000100_01111000_00000000_00000000          'prop1=1, busclk=0

PUB bus_putchar2(c)                                     'bus: byte an prop1 (bellatrix) senden
{{bus_putchar2(c) - bus: byte senden an prop2 (bellatrix)}}
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa := %00000000_00111000_00000000_00000000          'prop2=0, wr=0
  outa[7..0] := c                                       'daten --> dbus
  outa[busclk] := 1                                     'busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  dira := db_in                                         'bus freigeben
  outa := %00001100_01111000_00000000_00000000           'wr=1, prop2=1, busclk=0

  'ram_rw.putchar2(c)
PUB bus_getchar2: wert                                  'bus: byte vom prop1 (bellatrix) empfangen
{{bus_getchar2:wert - bus: byte empfangen von prop2 (bellatrix)}}
'  wert:=ram_rw.getchar2
  outa := %00000110_00111000_00000000_00000000          'prop2=0, wr=1, busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  wert := ina[7..0]                                     'daten einlesen
  outa := %00000100_01111000_00000000_00000000          'prop2=1, busclk=0

PUB bus_putchar3(c)                                     'bus: byte an prop1 (bellatrix) senden
{{bus_putchar2(c) - bus: byte senden an prop3 (venatrix)}}
' outa := %00001000_01011000_00000000_00000000          'prop1=0, wr=0
' outa := %00001000_00111000_00000000_00000000          'prop2=0, wr=0
' outa := %00001000_01111000_00000000_00000000          'prop3=0, wr=0

  outa := %00001000_01111000_00000000_00000000          'prop3=0, wr=0
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa[7..0] := c                                       'daten --> dbus
  outa[busclk] := 1                                     'busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  dira := db_in                                         'bus freigeben
  outa := %00001100_01111000_00000000_00000000           'wr=1, prop3=1, busclk=0

  'ram_rw.putchar2(c)
PUB bus_getchar3: wert                                  'bus: byte vom prop1 (bellatrix) empfangen
{{bus_getchar3:wert - bus: byte empfangen von prop3 (venatrix)}}
  outa := %00000110_01111000_00000000_00000000          'prop3=0, wr=1, busclk=1
  waitpeq(%00000000_00000000_00000000_00000000,%00001000_00000000_00000000_00000000,0) 'hs=0?
  wert := ina[7..0]                                     'daten einlesen
  outa := %00000100_01111000_00000000_00000000          'prop3=1, busclk=0

PUB bus_getword2: wert                                  'bus: 16 bit von bellatrix empfangen hsb/lsb

  wert := bus_getchar2 << 8
  wert := wert + bus_getchar2

PUB bus_putword2(wert)                                  'bus: 16 bit an bellatrix senden hsb/lsb

   bus_putchar2(wert >> 8)
   bus_putchar2(wert)

PUB bus_getlong2: wert                                  'bus: long von bellatrix empfangen hsb/lsb

  wert :=        bus_getchar2 << 24                     '32 bit empfangen hsb/lsb
  wert := wert + bus_getchar2 << 16
  wert := wert + bus_getchar2 << 8
  wert := wert + bus_getchar2

PUB bus_putlong2(wert)                                  'bus: long an bellatrix senden hsb/lsb
    repeat 4
       bus_putchar2(wert <-= 8)                            '32bit wert senden hsb/lsb
{
   bus_putchar2(wert >> 24)                             '32bit wert senden hsb/lsb
   bus_putchar2(wert >> 16)
   bus_putchar2(wert >> 8)
   bus_putchar2(wert)
   }
PUB bus_getword3: wert                                  'bus: 16 bit von venatrix empfangen hsb/lsb

  wert := bus_getchar3 << 8
  wert := wert + bus_getchar3

PUB bus_putword3(wert)                                  'bus: 16 bit an venatrix senden hsb/lsb

   bus_putchar3(wert >> 8)
   bus_putchar3(wert)

PUB bus_getlong3: wert                                  'bus: long von venatrix empfangen hsb/lsb

  wert :=        bus_getchar3 << 24                     '32 bit empfangen hsb/lsb
  wert := wert + bus_getchar3 << 16
  wert := wert + bus_getchar3 << 8
  wert := wert + bus_getchar3

PUB bus_putlong3(wert)                                  'bus: long an venatrix senden hsb/lsb
    repeat 4
       bus_putchar3(wert <-= 8)                            '32bit wert senden hsb/lsb
{
   bus_putchar3(wert >> 24)                             '32bit wert senden hsb/lsb
   bus_putchar3(wert >> 16)
   bus_putchar3(wert >> 8)
   bus_putchar3(wert)
   }
PUB bus_getstr3: stradr | len,i                         'bus: string von administra empfangen

    len  := bus_getchar3                                'längenbyte empfangen
    repeat i from 0 to len - 1                          '20 zeichen dateinamen empfangen
      strpuffer[i] := bus_getchar3
    strpuffer[i] := 0
    return @strpuffer

PUB bus_putstr3(stradr) | len,i                         'bus: string zu administra senden

  len := strsize(stradr)
  bus_putchar3(len)
  repeat i from 0 to len - 1
    bus_putchar3(byte[stradr++])

CON ''------------------------------------------------- eRAM/SPEICHERVERWALTUNG
{

Und so funktioniert es: Der Speicher (hier geht es nur um den eRAM!) ist in drei Teile gesplittet:

    1. Ramdisk
    2. Heap
    3. Systemvariablen

Wofür ist das jetzt gut?

Das unkomlizierte Speichermodell: Wenn man in seinem Programm unkompliziert Speicher braucht, der nicht resident
gehalten werden braucht, nutzt man einfach die Routinen ram_* um auf diesen zuzugreifen. Nach dem Beenden
des Programms ist dieser Speicher (Heap) aber dann vogelfrei. Für die Adressierung mit diesen Routinen gibt es
zwei Modis:

     1. sysmod - Hier entspricht die Adresse 0 auch der wirklichen physischen Adresse 0.
     2. usrmod - Hier entspricht die Adresse 0 dem Wert von "rbas" - ist also virtuell.

In einem normalen Programm wird man den usrmod verwenden und nur auf den freien Speicher (Heap) zwischen rbas
und rend zugreifen. Das klingt im ersten Moment kompliziert, ist aber ganz einfach: wenn es einfach sein soll,
arbeite ich im usrmod und bekomme von Adresse 0000..nnnn den Bereich zwischen Ramdisk und den Systemvariablen
(rbas..rend) zu "sehen". Möchte aber ein Systemprogramm zum Beispiel auf die Systemvariablen oder die Internas
der Ramdisk zugreifen, so ist der sysmod gefragt. In diesem Modus wird der eRAM direkt adressiert.

Die Ramdisk: Braucht die Anwendung aber residenten Speicher, so kann man sich einen Speicherblock als
Datei in der Ramdisk erzeugen und auf den Inhalt auch per direkter Adressierung mit rd_rdbyte/rd_wrbyte
zugreifen. In der Kommandozeile Regime ist es dann möglich, per xdir/xload und xsave auf diesen Speicher
bzw. Dateien zuzugreifen.

Ach ja: Mit der Ramdisk ist es auch möglich mehrere Dateien zu öffnen und zu verwenden - rd_open liefert dafür
eine Filenummer fnr, die man bei allen Operationen benutzen muss! :)

Wichtig ist es nur zu verstehen, dass der freie Speicher bei Verwendung der Ramdisk vogelfrei ist,
wenn die Anwendung beendet wird: Speichert ein Programm dort Daten und kehrt zur Kommandozeile zurück,
wird zum Beispiel durch laden oder speichern einer Datei in der Ramdisk die Variable "rbas" und
damit der freie Bereich in seiner Größe verändert ---> unsere Daten im freien Bereich befinden sich also nun
im usrmod an einer anderen Stelle oder sind überschrieben.


  memory-map:

  0000   -->    datei 1                                 'ab adresse 0 liegen die dateien der ramdisk als
                datei 2                                 'verkettete liste. das erste freie byte hinter der
                ...                                     'wird mit der variable "rbas" definiert.
                datei n

  rbas   -->    usermem start                           'zwischen rbas und rend liegt der freie ram.
                ...
  rend   -->    usermen ende

  sysvar -->    systemvariablen                         'ab dieser adresse befinden sich die systemvariablem im eram


  aufbau datei ramdisk:

  1  long       zeiger auf nächste datei                (oder 0 bei letzter datei)
  1  long       datenlänge
  12 byte       dateiname                               8+3-string
  nn byte       daten

  aufbau ftab:

  fnr                           dateinummer

  fnr 0         usermem
  fnr 1..7      dateien

  fix := fnr * FCNT             index in ftab

  ftab[fix+0]   startadresse daten
  ftab[fix+1]   endadresse daten
  ftab[fix+2]   position in datei
}

CON

  STARTRD       = $80000        'startadresse der ramdisk
  FILES         = 8             'maximale anzahl von RAMDisk-Dateien, die gleichzeitig geöffnet werden können
  FTCNT         = 3             'anzahl longs pro eintrag

  sysmod        = 0
  usrmod        = 1

  RDHLEN        = 20            ' 4+4+12 - headerlänge

VAR

'  long  ftab[(files)*FTCNT]     'filedeskriptortabelle
                                '1. long = startadresse daten
                                '2. long = endadresse daten
                                '3. long = position in der datei
'  long  dpos                    'position im dir (dir/next)
'  byte  dstr[13]                'string für dateinamen


PUB ram_rdbyte(adresse):wert                        'eram: liest ein byte vom eram
{{ram_rdbyte(adresse):wert - eram: ein byte aus externem ram lesen}}
'rambank 1                      000000 - 07FFFF
'rambank 2                      080000 - 0FFFFF
'sys = 0 - systemmodus, keine virtualisierung
'sys = 1 - usermodus, virtualisierte adresse
'sysmodus: der gesamte speicher (2 x 512 KB) werden durchgängig adressiert
'usermodus: adresse 0   = rambas
'           adresse max = ramend
 wert:=ram_rw.rd_value(adresse,ram_rw#JOB_PEEK)'ram_rw.peek(adresse)
{  if sys                                  'usermodus?
    adresse += rbas                       'adresse virtualisieren
    if adresse > rend                     'adressbereich überschritten?
      return 0

  outa[15..8] := adresse >> 11            'höherwertige adresse setzen
  outa[23] := 1                           'obere adresse in adresslatch übernehmen
  outa[23] := 0
  outa[18..8] := adresse                  'niederwertige adresse setzen
  if adresse < $080000                    'rambank 1?
    outa[reg_ram1] := 0                   'ram1 selektieren (wert wird geschrieben)
    wert := ina[7..0]                     'speicherzelle einlesen
    outa[reg_ram1] := 1                   'ram1 deselektieren
  else
    outa[reg_ram2] := 0                   'ram2 selektieren (wert wird geschrieben)
    wert := ina[7..0]                     'speicherzelle einlesen
    outa[reg_ram2] := 1                   'ram2 deselektieren
}
pub ram_fill(adresse,adresse2,wert)
    ram_rw.ram_fill(adresse,adresse2,wert)
{pub getadr:wert
    wert:=ram_rw.getadr
}
'pub ram_readline(adresse):line

'    line:=ram_rw.read(adresse)
pub ram_copy(von,ziel,anzahl)
    ram_rw.ram_copy(von,ziel,anzahl)
pub ram_keep(adr):w
    w:=ram_rw.ram_keep(adr)

PUB ram_wrbyte(wert,adresse)                        'eram: schreibt ein byte in eram
{{ram_wrbyte(wert,adresse) - eram: ein byte in externen ram schreiben}}
'rambank 1                      000000 - 07FFFF
'rambank 2                      080000 - 08FFFF
'sys = 0 - systemmodus, keine virtualisierung
'sys = 1 - usermodus, virtualisierte adresse
'sysmodus: der gesamte speicher (2 x 512 KB) werden durchgängig adressiert
'usermodus: adresse 0   = rambas
'           adresse max = ramend
'
ram_rw.wr_value(adresse,wert,ram_rw#JOB_POKE)
{  if sys                                 'usermodus?
    adresse += rbas                       'adresse virtualisieren
    if adresse > rend                     'adressbereich überschritten?
      return

  outa[bus_wr] := 0                       'schreiben aktivieren
  dira := db_out                          'datenbus --> ausgang
  outa[7..0] := wert                      'wert --> datenbus
  outa[15..8] := adresse >> 11            'höherwertige adresse setzen
  outa[23] := 1                           'obere adresse in adresslatch übernehmen
  outa[23] := 0
  outa[18..8] := adresse                  'niederwertige adresse setzen
  if adresse < $080000                    'rambank 1?
    outa[reg_ram1] := 0                   'ram1 selektieren (wert wird geschrieben)
    outa[reg_ram1] := 1                   'ram1 deselektieren
  else
    outa[reg_ram2] := 0                   'ram2 selektieren (wert wird geschrieben)
    outa[reg_ram2] := 1                   'ram2 deselektieren
  dira := db_in                           'datenbus --> eingang
  outa[bus_wr] := 1                       'schreiben deaktivieren
}
PUB ram_rdlong(eadr): wert                          'eram: liest long ab eadr
{{ram_rdlong - eram: liest long ab eadr}}
'sys = 0 - systemmodus, keine virtualisierung
'sys = 1 - usermodus, virtualisierte adresse
wert:=ram_rw.rd_value(eadr,ram_rw#JOB_RDLONG)'ram_rw.rd_long(eadr)
{  wert := ram_rdbyte(eadr)
  wert += ram_rdbyte(eadr + 1) << 8
  wert += ram_rdbyte(eadr + 2) << 16
  wert += ram_rdbyte(eadr + 3) << 24
}
PUB ram_rdword(eadr): wert                          'eram: liest word ab eadr
{{ram_rdlong(eadr):wert - eram: liest word ab eadr}}
'sys = 0 - systemmodus, keine virtualisierung
'sys = 1 - usermodus, virtualisierte adresse
wert:=ram_rw.rd_value(eadr,ram_rw#JOB_RDWORD)'ram_rw.rd_word(eadr)
{  wert := ram_rdbyte(eadr)
  wert += ram_rdbyte(eadr + 1) << 8
}
PUB ram_wrlong(wert,eadr)                        'eram: schreibt long ab eadr
{ram_wrlong(wert,eadr) - eram: schreibt long ab eadr}
'sys = 0 - systemmodus, keine virtualisierung
'sys = 1 - usermodus, virtualisierte adresse
  ram_rw.wr_value(eadr,wert,ram_rw#JOB_WRLONG)
{  n := wert & $FF
  ram_wrbyte(n,eadr)
  n := (wert >> 8) & $FF
  ram_wrbyte(n,eadr + 1)
  n := (wert >> 16) & $FF
  ram_wrbyte(n,eadr + 2)
  n := (wert >> 24) & $FF
  ram_wrbyte(n,eadr + 3)
}
PUB ram_wrword(wert,eadr)                        'eram: schreibt word ab eadr
{{wr_word(wert,eadr) - eram: schreibt word ab eadr}}
'sys = 0 - systemmodus, keine virtualisierung
'sys = 1 - usermodus, virtualisierte adresse
  ram_rw.wr_value(eadr,wert,ram_rw#JOB_WRWORD)
{  n := wert & $FF
  ram_wrbyte(n,eadr)
  n := (wert >> 8) & $FF
  ram_wrbyte(n,eadr + 1)
}
{pub tokrd(adr)
    return ram_rw.tokenrd(adr)
}

CON ''------------------------------------------------- TOOLS

{PUB hram_print(adr,rows)

  repeat rows
    printnl
    printhex(adr,4)
    printchar(":")
    printchar(" ")
    repeat 8
      printhex(byte[adr++],2)
      printchar(" ")
    adr := adr - 8
    repeat 8
      printqchar(byte[adr++])
}
PUB Dump(adr,line,mod) |zeile ,c[8] ,p,i  'adresse, anzahl zeilen,ram oder xram
  zeile:=0
  p:=getx+23
  repeat line
    printnl
    printhex(adr,5)
    printchar(":")

    repeat i from 0 to 7
      if mod>0
         c[i]:=ram_rdbyte(adr++)
      else
         c[i]:=byte[adr++]
      printhex(c[i],2)
      printchar(" ")

    repeat i from 0 to 7
      printqchar(c[i])

    zeile++
    if zeile == 12
       printnl
       print(string("<WEITER? */esc:>"))
       if keywait == 27
          printnl
            quit
       zeile:=0

DAT
                        org 0
'
' Entry
'
entry                   jmp     #entry                   'just loops


regsys        byte  "reg.sys",0
'belsys        byte  "bel.sys",0
'admsys        byte  "adm.sys",0


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

                                                                                                                                            
