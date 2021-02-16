{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ Autor: Ingo Kripahle                                                                                 │
│ Copyright (c) 2010 Ingo Kripahle                                                                     │
│ See end of file for terms of use.                                                                    │
│ Die Nutzungsbedingungen befinden sich am Ende der Datei                                              │
└──────────────────────────────────────────────────────────────────────────────────────────────────────┘

Informationen   : hive-project.de
Kontakt         : zille9@googlemail.com
System          : TriOS
Name            : Administra-Flash (SD,SID)
Chip            : Administra
Typ             : Flash
Version         : 00
Subversion      : 01

Funktion        : Diese Codeversion basiert auf admsid.spin und dient als Basis für die Micromite-version


                  
                  Dieser Code wird von  Administra nach einem Reset aus dem EEProm in den hRAM kopiert
                  und gestartet. Im Gegensatz zu Bellatrix und Regnatix, die einen Loader aus dem EEProm
                  laden und entsprechende Systemdateien vom SD-Cardlaufwerk booten, also im
                  wesentlichen vor dem Bootvorgang keine weiter Funktionalität als die Ladeprozedur
                  besitzen, muß das EEProm-Bios von Administra mindestens die Funktionalität des
                  SD-Cardlaufwerkes zur Verfügung stellen können. Es erscheint deshalb sinnvoll, dieses
                  BIOS gleich mit einem ausgewogenen Funktionsumfang auszustatten, welcher alle Funktionen
                  für das System bietet. Durch eine Bootoption kann dieses BIOS aber zur Laufzeit
                  ausgetauscht werden, um das Funktionssetup an konkrete Anforderungen anzupassen.

                  Chip-Managment-Funktionen
                  - Bootfunktion für Administra
                  - Abfrage und Verwaltung des aktiven Soundsystems
                  - Abfrage Version und Spezifikation
                  
                  SD-Funktionen:
                  - FAT32 oder FAT16
                  - Partitionen bis 1TB und Dateien bis 2GB
                  - Verzeichnisse
                  - Verwaltung aller Dateiattribute
                  - DIR-Marker System
                  - Verwaltung eines Systemordners
                  - Achtung: Keine Verwaltung von mehreren geöffneten Dateien!

                  SIDCog-Funktionen:

                  
                  

Komponenten     : SIDCog         Ver. 080   Johannes Ahlebrand MIT Lizenz
                  FATEngine      01/18/2009 Kwabena W. Agyeman MIT Lizenz
                  RTCEngine      11/22/2009 Kwabena W. Agyeman MIT Lizenz
                  
COG's           : MANAGMENT     1 COG
                  FAT/RTC       1 COG
                  SIDCog's      1 COG
                  DMP/Tracker   1 COG   (dynamisch)
                  DCF-Empfänger 1 COG
                  I2C Slave     1 Cog 'Administra wird als I2C-Slave benutzt,damit der Hive vom Micromite gesteuert werden kann
                  -------------------
                                6 Cogs
                  
Logbuch         :

08-11-2014      - die Arbeit beginnt
                - LAN-Funktionalität entfernt -> kann vom Micromite übernommen werden
                - Bluetooth-Funktion entfernt -> -------------- II ------------------
                - Plexbus-Funktionen entfern  -> -------------- II ------------------
                - 3043 Longs frei



}}


CON

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000

'signaldefinitionen administra

#0,     D0,D1,D2,D3,D4,D5,D6,D7                         'datenbus
#8,     ADM_SOUNDL,ADM_SOUNDR                           'sound (stereo 2 pin)
#10,    ADM_SDD0,ADM_SDCLK,ADM_SDCMD,ADM_SDD3           'sd-cardreader (4 pin)
#23,    ADM_SELECT                                      'administra-auswahlsignal
#24,    HBEAT                                           'front-led
        BUSCLK                                          'bustakt
        BUS_WR                                          '/wr - schreibsignal
        BUS_HS '                                        '/hs - quittungssignal

'                   +----------
'                   |  +------- system     
'                   |  |  +---- version    (änderungen)
'                   |  |  |  +- subversion (hinzufügungen)
CHIP_VER        = $00_01_01_01
'                                          +----------- Micromite
'                                          |+---------- com
'                                          || +-------- i2c
'                                          || |+------- rtc
'                                          || ||+------ lan
'                                          || |||+----- sid
'                                          || ||||+---- wav
'                                          || |||||+--- hss
'                                          || ||||||+-- bootfähig
'                                          || |||||||+- dateisystem
CHIP_SPEC       = %00000000_00000000_00000010_11010011
'A_FAT           = %00000000_00000000_00000000_00000001
'A_LDR           = %00000000_00000000_00000000_00000010
'A_HSS           = %00000000_00000000_00000000_00000100
'A_WAV           = %00000000_00000000_00000000_00001000
'A_SID           = %00000000_00000000_00000000_00010000
'A_LAN           = %00000000_00000000_00000000_00100000
'A_RTC           = %00000000_00000000_00000000_01000000
'A_PLX           = %00000000_00000000_00000000_10000000
'A_COM           = %00000000_00000000_00000001_00000000
'A_AYS           = %00000000_00000000_00000010_00000000

'
'          hbeat   --------+                            
'          clk     -------+|                            
'          /wr     ------+|| +------------------------- /cs
'          /hs     -----+||| |
'                       |||| |                 +------+ d0..d7
'                       |||| |                 |      |
DB_IN            = %00001001_00000000_00000000_00000000 'dira-wert für datenbuseingabe
DB_OUT           = %00001001_00000000_00000000_11111111 'dira-wert für datenbusausgabe

M1               = %00000010_00000000_00000000_00000000 'busclk=1? & /prop1=0?
M2               = %00000010_10000000_00000000_00000000 'maske: busclk & /cs (/prop1)

M3               = %00000000_00000000_00000000_00000000 'busclk=0?
M4               = %00000010_00000000_00000000_00000000 'maske: busclk



LED_OPEN        = HBEAT                                 'led-pin für anzeige "dateioperation"
SD_BASE         = ADM_SDD0                              'baspin cardreader
'Bluetooth_Line  = 21                                    'Key-Line des HC05-Bluetooth-Moduls (Programmiermodus)


'index für dmarker
#0,     RMARKER                                         'root
        SMARKER                                         'system
        UMARKER                                         'programmverzeichnis
        AMARKER
        BMARKER
        CMARKER

'sidcog

playRate        = 50            'Hz
detune          = 1.006

'' uMite I2C Connection Settings
   SDA_pin       = 19'14         ''IMPORTANT NOTE:
   SCL_pin       = 18'18 für Hive-Max 20'15         ''THESE TWO LINES REQUIRE 10K PULL-UP RESISTORS
   Bitrate       = 400_000


OBJ
                sdfat           : "adm-fat"        'fatengine
                sid1            : "sidcog"         'SIDCog
                rtc             : "adm-rtc"
                'ser             : "SerialMirror"
                gc              : "glob-microm"
                'dcf             : "dcf77"          'Funkuhrmodul
                num             : "glob-numbers"   'Number Engine
                'slave           : "I2C slave v1.2" 'I2C-Slave-Treiber

VAR

  long  dmarker[6]                                      'speicher für dir-marker
  byte  tbuf[20]                                        'stringpuffer
  byte  tbuf2[20]

  long  sidreg1                                         'adresse register der sidcog 1
  long  dmpcog                                          'id der dmp-player-cog
  long  aydmpcog                                        'id der ay-dmp-player-cog
  long  dmpstack[50]                                    'stack für dmpcog
  byte  sidbuffer[25]                                   'puffer für dmpcog
  byte  dmpstatus                                       '0 = inaktiv; 1 = play; 2 = pause
  long  dmppos                                          'position des players im dump
  long  dmplen                                          'länge des dmp-files (anzahl regsitersätze)
  byte  dmppause                                        'pauseflag
  byte  s1buffer[25]                                    'registerpuffer sid1

  byte  dcfon                                           'DCF-Betriebsmerker
                                                        '(zum Socket mit dem Handle 2 gehört der Pufferabschnitt aus bufidx[2])
  byte  bufrx[4096]                                     'Kopierpuffer
  byte i2c
  byte register[32]
  byte sdata

CON ''------------------------------------------------- ADMINISTRA
PUB main | cmd,err,a ,b,c,d,e,f,g,sy,tmp,i                'chip: kommandointerpreter
''funktionsgruppe               : chip
''funktion                      : kommandointerpreter
''eingabe                       : -
''ausgabe                       : -

  init_chip                                             'bus/vga/keyboard/maus initialisieren
  repeat

    cmd := bus_getchar                                  'kommandocode empfangen
    'if dcfon
    '   if dcf.GetInSync==1
    '      if dcf.GetBitNumber==59                       'Zeittelegramm gültig?, dann RTC synchronisieren (jedes gültige Telegramm)
    '          Update_Clock

    err := 0

    case cmd
        0:  !outa[LED_OPEN]                             'led blinken

'       ----------------------------------------------  SD-FUNKTIONEN
        gc#a_sdMount: sd_mount("M")                     'sd-card mounten                                              '
        gc#a_sdOpenDir: sd_opendir                      'direktory öffnen
        gc#a_sdNextFile: sd_nextfile                    'verzeichniseintrag lesen
        gc#a_sdOpen: sd_open                            'datei öffnen
        gc#a_sdClose: sd_close                          'datei schließen
        gc#a_sdGetC: sd_getc                            'zeichen lesen
        gc#a_sdPutC: sd_putc                            'zeichen schreiben
        gc#a_sdGetBlk: sd_getblk                        'block lesen
        gc#a_sdPutBlk: sd_putblk                        'block schreiben
        gc#a_sdSeek: sd_seek                            'zeiger in datei positionieren
        gc#a_sdFAttrib: sd_fattrib                      'dateiattribute übergeben
        gc#a_sdVolname: sd_volname                      'volumelabel abfragen
        gc#a_sdCheckMounted: sd_checkmounted            'test ob volume gemounted ist
        gc#a_sdCheckOpen: sd_checkopen                  'test ob eine datei geöffnet ist
        gc#a_sdCheckUsed: sd_checkused                  'test wie viele sektoren benutzt sind
        gc#a_sdCheckFree: sd_checkfree                  'test wie viele sektoren frei sind
        gc#a_sdNewFile: sd_newfile                      'neue datei erzeugen
        gc#a_sdNewDir: sd_newdir                        'neues verzeichnis wird erzeugt
        gc#a_sdDel: sd_del                              'verzeichnis oder datei löschen
        gc#a_sdRename: sd_rename                        'verzeichnis oder datei umbenennen
        gc#a_sdChAttrib: sd_chattrib                    'attribute ändern
        gc#a_sdChDir: sd_chdir                          'verzeichnis wechseln
        gc#a_sdFormat: sd_format                        'medium formatieren
        gc#a_sdUnmount: sd_unmount                      'medium abmelden
        gc#a_sdDmAct: sd_dmact                          'dir-marker aktivieren
        gc#a_sdDmSet: sd_dmset                          'dir-marker setzen
        gc#a_sdDmGet: sd_dmget                          'dir-marker status abfragen
        gc#a_sdDmClr: sd_dmclr                          'dir-marker löschen
        gc#a_sdDmPut: sd_dmput                          'dir-marker status setzen
        gc#a_sdEOF: sd_eof                              'eof abfragen
        gc#a_sdPOS:sd_pos                               'Datenzeiger innerhalb einer Datei
        gc#a_sdCOPY:sd_copy                             'Datei kopieren

'       ----------------------------------------------  RTC-FUNKTIONEN
        gc#a_rtcGetSeconds: rtc_getSeconds              'Returns the current second (0 - 59) from the real time clock.
        gc#a_rtcGetMinutes: rtc_getMinutes              'Returns the current minute (0 - 59) from the real time clock.
        gc#a_rtcGetHours: rtc_getHours                  'Returns the current hour (0 - 23) from the real time clock.
        gc#a_rtcGetDay: rtc_getDay                      'Returns the current day (1 - 7) from the real time clock.
        gc#a_rtcGetDate: rtc_getDate                    'Returns the current date (1 - 31) from the real time clock.
        gc#a_rtcGetMonth: rtc_getMonth                  'Returns the current month (1 - 12) from the real time clock.
        gc#a_rtcGetYear: rtc_getYear                    'Returns the current year (2000 - 2099) from the real time clock.
        gc#a_rtcSetSeconds: rtc_setSeconds              'Sets the current real time clock seconds. Seconds - Number to set the seconds to between 0 - 59.
        gc#a_rtcSetMinutes: rtc_setMinutes              'Sets the current real time clock minutes. Minutes - Number to set the minutes to between 0 - 59.
        gc#a_rtcSetHours: rtc_setHours                  'Sets the current real time clock hours. Hours - Number to set the hours to between 0 - 23.
        gc#a_rtcSetDay: rtc_setDay                      'Sets the current real time clock day. Day - Number to set the day to between 1 - 7.
        gc#a_rtcSetDate: rtc_setDate                    'Sets the current real time clock date. Date - Number to set the date to between 1 - 31.
        gc#a_rtcSetMonth: rtc_setMonth                  'Sets the current real time clock month. Month - Number to set the month to between 1 - 12.
        gc#a_rtcSetYear: rtc_setYear                    'Sets the current real time clock year. Year - Number to set the year to between 2000 - 2099.
        gc#a_rtcSetNVSRAM: rtc_setNVSRAM                'Sets the NVSRAM to the selected value (0 - 255) at the index (0 - 55).
        gc#a_rtcGetNVSRAM: rtc_getNVSRAM                'Gets the selected NVSRAM value at the index (0 - 55).
        gc#a_rtcPauseForSec: rtc_pauseForSeconds        'Pauses execution for a number of seconds. Returns a puesdo random value derived from the current clock frequency and the time when called. Number - Number of seconds to pause for between 0 and 2,147,483,647.
        gc#a_rtcPauseForMSec: rtc_pauseForMilliseconds  'Pauses execution for a number of milliseconds. Returns a puesdo random value derived from the current clock frequency and the time when called. Number - Number of milliseconds to pause for between 0 and 2,147,483,647.
        gc#a_rtcTest: rtc_test                          'Test if RTC Chip is available

 {       gc#a_DCF_INSYNC: bus_putchar(dcf.GetInSync)     'Sync-Status senden
        gc#a_DCF_UPDATE_CLOCK: Update_Clock             'RTC Synchronisieren
        gc#a_DCF_GETBITERROR: bus_putchar(dcf.GetBitError)   '\
        gc#a_DCF_GETDatacount: Bus_putchar(dcf.GetDatacount)  '|
        gc#a_DCF_GetBitNumber: bus_putchar(dcf.GetBitNumber)  ' > diverse DCF-Parameter
        gc#a_DCF_GetBitLevel: bus_putchar(dcf.GetBitLevel)    '|
        gc#a_DCF_GetTimeZone: bus_putchar(dcf.GetTimeZone)    '|
        gc#a_DCF_GetActiveSet: bus_putchar(dcf.GetActiveSet)  '/
        gc#a_DCF_start: dcf.start                       'DCF-Empfang starten
            dcfon:=1
        gc#a_DCF_stop: dcf.stop                         'DCF-Empfang stoppen
            dcfon:=0
            sy:=0                                       'Sync-Status löschen
        gc#a_DCF_dcfon: bus_putchar(dcfon)              'Status des DCF-Empfängers

        gc#a_DCF_Getseconds: bus_putchar(dcf.getseconds)
        gc#a_DCF_GetMinutes: bus_putchar(dcf.GetMinutes)
        gc#a_DCF_Gethours: bus_putchar(dcf.gethours)
        gc#a_DCF_GetWeekDay: bus_putchar(dcf.GetWeekDay)
        gc#a_DCF_GetDay: bus_putchar(dcf.GetDay)
        gc#a_DCF_GetMonth: bus_putchar(dcf.GetMonth)
        gc#a_DCF_GetYear: sub_putword(dcf.GetYear)     }
'       ----------------------------------------------  I2C-Slave
{        gc#a_slaveadress:'slave.Address
                         repeat i from 2 to 17
                              bus_putchar(slave.get(i))
        gc#a_slaveput   :a:=bus_getchar
                         b:=bus_getchar
                         slave.put(a,b)
        gc#a_slaveget   :a:=bus_getchar
                         bus_putchar(slave.get(a))
        gc#a_slaveflush :slave.flush
        gc#a_slavedone  :bus_putchar(slave.IsDone)
        gc#a_slavecleardone:slave.ClearDone
        gc#a_Checkregister:sub_putlong(slave.Check_Reg(bus_getchar))
}
'       ----------------------------------------------  CHIP-MANAGMENT
        gc#a_mgrGetSpec: mgr_getspec                    'spezifikation abfragen
        gc#a_mgrALoad: mgr_aload                        'neuen code booten
        gc#a_mgrGetCogs: mgr_getcogs                    'freie cogs abfragen
        gc#a_mgrGetVer: mgr_getver                      'codeversion abfragen
        gc#a_mgrReboot: reboot                          'neu starten
'       ----------------------------------------------  SIDCog: DMP-Player-Funktionen (SIDCog2)
        gc#a_s_dmplen: sid_dmplen                       'dmp-file-laenge
        gc#a_s_mdmpplay: sid_mdmpplay                   'dmp-file mono auf sid2 abspielen
        gc#a_s_sdmpplay: sid_sdmpplay                   'dmp-file stereo auf beiden sids abspielen
        gc#a_s_dmpstop: sid_dmpstop                     'dmp-player beenden
        gc#a_s_dmppause: sid_dmppause                   'dmp-player pausenmodus
        gc#a_s_dmpstatus: sid_dmpstatus                 'dmp-player statusabfrage
        gc#a_s_dmppos: sid_dmppos                       'player-position im dumpfile
        gc#a_s_mute: sid_mute                           'alle register löschen
'       ----------------------------------------------  SIDCog1-Funktionen
        gc#a_s1_setRegister:    a:=bus_getchar
                                b:=bus_getchar
                                sid1.setRegister(a,b)
        gc#a_s1_updateRegisters: sid1.updateRegisters(sub_getdat(25,@s1buffer))
        gc#a_s1_setVolume:      a:=bus_getchar
                                sid1.setVolume(a)
        gc#a_s1_play:           a:=bus_getchar
                                b:=note2freq(bus_getchar)
                                c:=bus_getchar
                                d:=bus_getchar
                                e:=bus_getchar
                                f:=bus_getchar
                                g:=bus_getchar
                                sid1.play(a,b,c,d,e,f,g)
        gc#a_s1_noteOn:
                                a:=bus_getchar
                                b:=bus_getchar
                                sid1.noteOn(a,note2freq(b))

        gc#a_s1_noteOff:        a:=bus_getchar
                                sid1.noteOff(a)
        gc#a_s1_setFreq:        a:=bus_getchar
                                b:=sub_getlong
                                sid1.setFreq(a,b)
        gc#a_s1_setWaveform:    a:=bus_getchar
                                b:=bus_getchar
                                sid1.setWaveform(a,b)
        gc#a_s1_setPWM:         a:=bus_getchar
                                b:=sub_getlong
                                sid1.setPWM(a,b)
        gc#a_s1_setADSR:        c:=bus_getchar
                                d:=bus_getchar
                                e:=bus_getchar
                                f:=bus_getchar
                                g:=bus_getchar
                                sid1.setADSR(c,d,e,f,g)
        gc#a_s1_setResonance:   a:=bus_getchar
                                sid1.setResonance(a)
        gc#a_s1_setCutoff:      b:=sub_getlong
                                sid1.setCutoff(b)
        gc#a_s1_setFilterMask:  c:=bus_getchar
                                d:=bus_getchar
                                e:=bus_getchar
                                sid1.setFilterMask(c,d,e)
        gc#a_s1_setFilterType:  c:=bus_getchar
                                d:=bus_getchar
                                e:=bus_getchar
                                sid1.setFilterType(c,d,e)
        gc#a_s1_enableRingmod:  c:=bus_getchar
                                d:=bus_getchar
                                e:=bus_getchar
                                sid1.enableRingmod(c,d,e)
        gc#a_s1_enableSynchronization: c:=bus_getchar
                                d:=bus_getchar
                                e:=bus_getchar
                                sid1.enableSynchronization(c,d,e)

        197: sid1.resetRegisters
        198: sid_Beep(bus_getchar)
        199: sid_dmpreg                                 'soundinformationen senden

PUB init_chip|i                                         'chip: initialisierung des administra-chips
''funktionsgruppe               : chip
''funktion                      : - initialisierung des businterface
''                                - grundzustand definieren (hss aktiv, systemklänge an)
''eingabe                       : -
''ausgabe                       : -


    repeat i from 0 to 7                                'evtl. noch laufende cogs stoppen
      ifnot i == cogid
        cogstop(i)

  'businterface initialisieren
  outa[bus_hs] := 1                                     'handshake inaktiv             ,frida
  dira := db_in                                         'datenbus auf eingabe schalten ,frida
    'sd-card starten
  clr_dmarker                                           'dir-marker löschen
  sdfat.FATEngine
  repeat
    waitcnt(cnt + clkfreq/10)
  until sd_mount("B") == 0

  sound_start                                           'sid_cog starten
  'RTC initialisieren
  rtc.setSQWOUTFrequency(3)                             'RTC Uhrenquarzt Frequenz wählen
  rtc.setSQWOUTState(0)                                 'RT Zähler ein

  'ser.start(31,30,0,9600)       ' debug
  dcfon:=0

  'slave.start(SCL_pin,SDA_pin,$42)

PUB bus_putchar(zeichen)                                'chip: ein byte über bus ausgeben
''funktionsgruppe               : chip
''funktion                      : senderoutine für ein byte zu regnatix über den systembus
''eingabe                       : byte zeichen
''ausgabe                       : -

  waitpeq(M1,M2,0)                                      'busclk=1? & /prop1=0?
  dira := db_out                                        'datenbus auf ausgabe stellen
  outa[7..0] := zeichen                                 'daten ausgeben
  outa[bus_hs] := 0                                     'daten gültig
  waitpeq(M3,M4,0)                                      'busclk=0?
  outa[bus_hs] := 1                                     'daten ungültig
  dira := db_in                                         'bus freigeben

PUB bus_getchar : zeichen                               'chip: ein byte über bus empfangen
''funktionsgruppe               : chip
''funktion                      : emfangsroutine für ein byte von regnatix über den systembus
''eingabe                       : -
''ausgabe                       : byte zeichen

  waitpeq(M1,M2,0)                                      'busclk=1? & /prop1=0?
  zeichen := ina[7..0]                                  'daten einlesen
  outa[bus_hs] := 0                                     'daten quittieren
  waitpeq(M3,M4,0)                                      'busclk=0?
  outa[bus_hs] := 1

PUB sub_putword(wert)                                   'sub: long senden
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen long-wert an regnatix zu senden
''eingabe                       : 32bit wert der gesendet werden soll
''ausgabe                       : -
''busprotokoll                  : [put.byte1][put.byte2][put.byte3][put.byte4]
''                              : [  hsb    ][         ][         ][   lsb   ]

   bus_putchar(wert >> 8)
   bus_putchar(wert)

PUB clr_dmarker| i                                      'chip: dmarker-tabelle löschen
''funktionsgruppe               : chip
''funktion                      : dmarker-tabelle löschen
''eingabe                       : -
''ausgabe                       : -

    i := 0
    repeat 6                                            'alle dir-marker löschen
      dmarker[i++] := TRUE

CON ''------------------------------------------------- SIDCog: DMP-Player-Funktionen (SIDCog2)

PUB sound_start
  'soundsystem initialisieren
  sidreg1 := sid1.start(ADM_SOUNDL,ADM_SOUNDR)                      'erste sidcog starten, adresse der register speichern

Pub sound_stop
    sid1.stop
    'sid2.stop
PRI sid_mdmpplay | err                                  'sid: dmp-datei mono auf sid2 abspielen
''funktionsgruppe               : sid
''funktion                      : dmp-datei mono auf sid2 abspielen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [157][sub_getstr.fn][put.error]
''                              : fn - name der dmp-datei
''                              : error - fehlernummer entspr. list
   sub_getstr
   err := \sdfat.openFile(@tbuf, "r")
   if err == 0
      dmppause := 0
      dmpcog := cognew(sid_dmpmcog,@dmpstack) + 1       'player-cog starten
   bus_putchar(err)                                     'ergebnis der operation senden

PRI sid_sdmpplay | err                                  'sid: dmp-datei stereo auf beiden sid's abspielen

   sub_getstr
   err := \sdfat.openFile(@tbuf, "r")
   if err == 0
      dmppause := 0
      dmpcog := cognew(sid_dmpscog,@dmpstack) + 1       'player-cog starten

   bus_putchar(err)                                     'ergebnis der operation senden

PRI sid_dmpstop                                         'sid: dmp-player stoppen
  if dmpcog
    sid1.setVolume(0)
    cogstop(dmpcog-1)
    dmpstatus := 0

PRI sid_dmppause|i                                      'sid: dmp-player pause
  case dmppause
    0: dmppause := 1
       repeat until dmpstatus == 2
       sid1.setVolume(0)
    1: dmppause := 0

PRI sid_dmpstatus                                       'sid: status des dmp-players abfragen
  bus_putchar(dmpstatus)

PRI sid_dmppos                                          'sid: position/länge des dmp-players abfragen
  sub_putlong(dmplen-dmppos)
  'sub_putlong(dmplen)
pri sid_dmplen                                          'sid: länge des dmp-files abfragen
   sub_putlong(dmplen)

PRI sid_mute|sidnr,i                                    'sid: ruhe!

  repeat i from 0 to 25
    sidbuffer[i] := 0
  sid1.updateRegisters(@sidbuffer)

PRI sid_dmpmcog | i                                     'sid: dmpcog - mono, sid2

  dmpstatus := 1                                        'player läuft
  dmplen := \sdfat.listSize / 25
  dmppos := 0
  repeat dmplen
    waitcnt(cnt+(clkfreq/playRate))                     'warten auf den c64-vbl :)

   \sdfat.readData(@sidbuffer,25)                      '25 byte in den puffer einlesen

    sid1.updateRegisters(@sidbuffer)                    'puffer in die sid-register schreiben
    dmppos++
    if dmppause == 1
      dmpstatus := 2
    else
      dmpstatus := 1
    repeat while dmppause == 1                          'warten solange pause
  dmpstatus := 0                                        'player beendet

PRI sid_dmpscog | i                                     'sid: dmpcog - mono, sid2

  dmpstatus := 1                                        'player läuft
  dmplen := \sdfat.listSize / 25
  dmppos := 0
  repeat dmplen
    waitcnt(cnt+(clkfreq/playRate))                     'warten auf den c64-vbl :)

   \sdfat.readData(@sidbuffer,25)                      '25 byte in den puffer einlesen

    sid1.updateRegisters(@sidbuffer)                    'puffer in die sid-register schreiben
    dmppos := dmppos + 1
    if dmplen-dmppos<1
       sid_dmpstop

    if dmppause == 1
      dmpstatus := 2
    else
      dmpstatus := 1
    repeat while dmppause == 1                          'warten solange pause
  dmpstatus := 0                                        'player beendet

PRI sid_dmpreg                                          'sid: dmpregister senden

  bus_putchar(byte[@sidbuffer+1])                       'kanal 1
  bus_putchar(byte[@sidbuffer+0])
  bus_putchar(byte[@sidbuffer+8])                       'kanal 2
  bus_putchar(byte[@sidbuffer+7])
  bus_putchar(byte[@sidbuffer+15])                      'kanal 3
  bus_putchar(byte[@sidbuffer+14])

  bus_putchar(byte[@sidbuffer+24])                      'volume


pub sid_beep(n)
       sid1.setVolume($0F)
    if n==0                                     'normaler beep
       sid1.play(0,7500,16,0,0,15,5)
       waitcnt(cnt + 10_000_000)
       sid1.noteOff(0)
       sid1.play(0,11500,16,0,0,15,5)
       waitcnt(cnt + 10_000_000)
       sid1.noteOff(0)
    else                                        'beep mit bestimmter tonhoehe
       sid1.play(0,note2freq(n),16,0,0,15,5)
       waitcnt(cnt + 1_000_000)
       sid1.noteOff(0)
PUB note2freq(note) | octave
    octave := note/12
    note -= octave*12
    return (noteTable[note]>>(8-octave))
CON ''------------------------------------------------- RTC-FUNKTIONEN

{pri Update_Clock                'RTC-mit DCF-Daten synchronisieren

    rtc.setHours(dcf.GetHours)
    rtc.setMinutes(dcf.GetMinutes)
    rtc.setSeconds(dcf.GetSeconds)
    rtc.setYear(dcf.GetYear)
    rtc.setMonth(dcf.GetMonth)
    rtc.setDate(dcf.GetDay)
    rtc.setDay(dcf.GetWeekDay)
}
pri rtc_time
    sub_putlong(rtc.getHours)
    sub_putlong(rtc.getMinutes)
    sub_putlong(rtc.getSeconds)

PRI rtc_getSeconds              'Returns the current second (0 - 59) from the real time clock.
''funktionsgruppe               : rtc
''busprotokoll                  : [041][sub_putlong.seconds]
''                              : seconds - current second (0 - 59)
  sub_putlong(rtc.getSeconds)

PRI rtc_getMinutes              'Returns the current minute (0 - 59) from the real time clock.
''funktionsgruppe               : rtc
''busprotokoll                  : [042][sub_putlong.minutes]
''                              : minutes - current minute (0 - 59)
  sub_putlong(rtc.getMinutes)

PRI rtc_getHours                'Returns the current hour (0 - 23) from the real time clock.
''funktionsgruppe               : rtc
''busprotokoll                  : [043][sub_putlong.hours]
''                              : hours -  current hour (0 - 23)
  sub_putlong(rtc.getHours)

PRI rtc_getDay                  'Returns the current day of the week (1 - 7) from the real time clock.
''funktionsgruppe               : rtc
''busprotokoll                  : [044][sub_putlong.day]
''                              : day - current day (1 - 7) of the week
  sub_putlong(rtc.getDay)

PRI rtc_getDate                 'Returns the current date (1 - 31) from the real time clock.
''funktionsgruppe               : rtc
''busprotokoll                  : [045][sub_putlong.date]
''                              : date - current date (1 - 31) of the month
  sub_putlong(rtc.getDate)

PRI rtc_getMonth                'Returns the current month (1 - 12) from the real time clock.
''funktionsgruppe               : rtc
''busprotokoll                  : [046][sub_putlong.month]
''                              : month - current month (1 - 12)
  sub_putlong(rtc.getMonth)

PRI rtc_getYear                 'Returns the current year (2000 - 2099) from the real time clock.
''funktionsgruppe               : rtc
''busprotokoll                  : [047][sub_putlong.year]
''                              : year -  current year (2000 - 2099)
  sub_putlong(rtc.getYear)

PRI rtc_setSeconds : seconds    'Sets the current real time clock seconds.
''funktionsgruppe               : rtc
''busprotokoll                  : [048][sub_getlong.seconds]
''                              : seconds - Number to set the seconds to between 0 - 59.
  rtc.setSeconds(sub_getlong)

PRI rtc_setMinutes : minutes    'Sets the current real time clock minutes.
''funktionsgruppe               : rtc
''busprotokoll                  : [049][sub_getlong.minutes]
''                              : minutes - Number to set the minutes to between 0 - 59.
  rtc.setMinutes(sub_getlong)

PRI rtc_setHours                'Sets the current real time clock hours.
''funktionsgruppe               : rtc
''busprotokoll                  : [050][sub_getlong.hours]
''                              : hours - Number to set the hours to between 0 - 23.51:
  rtc.setHours(sub_getlong)

PRI rtc_setDay                  'Sets the current real time clock day.
''funktionsgruppe               : rtc
''busprotokoll                  : [051][sub_getlong.day]
''                              : day - Number to set the day to between 1 - 7.
  rtc.setDay(sub_getlong)

PRI rtc_setDate                 'Sets the current real time clock date.
''funktionsgruppe               : rtc
''busprotokoll                  : [052][sub_getlong.date]
''                              : date - Number to set the date to between 1 - 31.
  rtc.setDate(sub_getlong)

PRI rtc_setMonth                'Sets the current real time clock month.
''funktionsgruppe               : rtc
''busprotokoll                  : [053][sub_getlong.month]
''                              : month - Number to set the month to between 1 - 12.
  rtc.setMonth(sub_getlong)

PRI rtc_setYear                 'Sets the current real time clock year.
''funktionsgruppe               : rtc
''busprotokoll                  : [054][sub_getlong.year]
''                              : year - Number to set the year to between 2000 - 2099.
  rtc.setYear(sub_getlong)

PRI rtc_setNVSRAM | index, value    'Sets the NVSRAM to the selected value (0 - 255) at the index (0 - 55).
''funktionsgruppe               : rtc
''busprotokoll                  : [055][sub_getlong.index][sub_getlong.value]
''                              : index - The location in NVRAM to set (0 - 55).                                                                           │
''                              : value - The value (0 - 255) to change the location to.                                                                   │
  index := sub_getlong
  value := sub_getlong
  rtc.setNVSRAM(index, value)

PRI rtc_getNVSRAM               'Gets the selected NVSRAM value at the index (0 - 55).
''funktionsgruppe               : rtc
''busprotokoll                  : [056][sub_getlong.index][sub_getlong.value]
''                              : index - The location in NVRAM to get (0 - 55).                                                                           │
  sub_putlong(rtc.getNVSRAM(sub_getlong))

PRI rtc_pauseForSeconds         'Pauses execution for a number of seconds.
''funktionsgruppe               : rtc
''busprotokoll                  : [057][sub_getlong.number][sub_putlong.number]
''                              : Number - Number of seconds to pause for between 0 and 2,147,483,647.
''                              : Returns a puesdo random value derived from the current clock frequency and the time when called.

  sub_putlong(rtc.pauseForSeconds(sub_getlong))

PRI rtc_pauseForMilliseconds    'Pauses execution for a number of milliseconds.
''funktionsgruppe               : rtc
''busprotokoll                  : [058][sub_getlong.number][sub_putlong.number]
''                              : Number - Number of milliseconds to pause for between 0 and 2,147,483,647.
''                              : Returns a puesdo random value derived from the current clock frequency and the time when called.
  sub_putlong(rtc.pauseForMilliseconds(sub_getlong))

PRI probeRTC | hiveid

  hiveid := rtc.getNVSRAM(gc#NVRAM_HIVE)         'read first byte of hive id

  rtc.setNVSRAM(gc#NVRAM_HIVE, hiveid ^ $F)      'write back to NVRAM with flipped all bits
  if rtc.getNVSRAM(gc#NVRAM_HIVE) == hiveid ^ $F 'flipped bits are stored?
    rtc.setNVSRAM(gc#NVRAM_HIVE, hiveid)         'restore first byte of hive id
    return(TRUE)                              'RTC found
  else
    rtc.setNVSRAM(gc#NVRAM_HIVE, hiveid)         'still restore first byte of hive id
    return(FALSE)                             'no RTC found

PRI rtc_test                                            'rtc: Test if RTC Chip is available
''funktionsgruppe               : rtc
''busprotokoll                  : [059][put.avaliable]
''                              : Returns TRUE if RTC is available, otherwise FALSE
    bus_putchar(probeRTC)

CON ''------------------------------------------------- SUBPROTOKOLL-FUNKTIONEN

PUB sub_getstr | i,len                                  'sub: string einlesen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen string von regnatix zu empfangen und im
''                              : textpuffer (tbuf) zu speichern
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [get.len][get.byte(1)]..[get.byte(len)]
''                              : len - länge des dateinamens

  repeat i from 0 to 19                                 'puffer löschen und kopieren
    tbuf2[i] := tbuf[i]
    tbuf[i] := 0
  len := bus_getchar                                    'längenbyte name empfangen
  repeat i from 0 to len - 1                            'dateiname einlesen
    tbuf[i] := bus_getchar
  'tbuf[i] := 0
PUB sub_getdat(len,datadr1):datadr2 | i                 'sub: daten einlesen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um eine bestimmte anzahl bytes zu empfangen
''eingabe                       : len     - anzahl der bytes
''                              : datadr1 - adresse des datenspeichers
''ausgabe                       : datadr2 - adresse des datenspeichers
''busprotokoll                  : [get.byte(1)]..[get.byte(len)]

  repeat i from 0 to len - 1                            'dateiname einlesen
    tbuf[datadr1 + i] := bus_getchar
  datadr2 := datadr1

PUB sub_putstr(strptr)|len,i                            'sub: string senden
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen string an regnatix zu senden
''eingabe                       : strptr - zeiger auf einen string (0-term)
''ausgabe                       : -
''busprotokoll                  : [put.len][put.byte(1)]..[put.byte(len)]
''                              : len - länge des dateinamens

  len := strsize(strptr)                                
  bus_putchar(len)
  repeat i from 0 to len - 1                            'string übertragen
    bus_putchar(byte[strptr][i])

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

PRI sub_getword:wert                                    'sub: long empfangen
''funktionsgruppe               : sub
''funktion                      : subprotokoll um einen 16bit-wert von regnatix zu empfangen
''eingabe                       : -
''ausgabe                       : 16bit-wert der empfangen wurde
''busprotokoll                  : [get.byte1][get.byte2]
''                              : [  hsb    ][   lsb   ]

  wert := wert + bus_getchar << 8
  wert := wert + bus_getchar

CON ''------------------------------------------------- CHIP-MANAGMENT-FUNKTIONEN


PUB mgr_aload | err                                     'cmgr: neuen administra-code booten
''funktionsgruppe               : cmgr
''funktion                      : administra mit neuem code booten
''eingabe                       :
''ausgabe                       :
''busprotokoll                  : [096][sub_getstr.fn]
''                              : fn  - dateiname des neuen administra-codes
  'plx.halt
  'plx.stop
  sub_getstr
  err := \sdfat.bootPartition(@tbuf,".")


PUB mgr_getcogs: cogs |i,c,cog[8]                       'cmgr: abfragen wie viele cogs in benutzung sind
''funktionsgruppe               : cmgr
''funktion                      : abfrage wie viele cogs in benutzung sind
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [097][put.cogs]
''                              : cogs - anzahl der belegten cogs

  cogs := i := 0
  repeat 'loads as many cogs as possible and stores their cog numbers
    c := cog[i] := cognew(@entry, 0)
    if c=>0
      i++
  while c => 0
  cogs := i
  repeat 'unloads the cogs and updates the string
    i--
    if i=>0
      cogstop(cog[i])
  while i=>0
  bus_putchar(cogs)


PUB mgr_getver                                          'cmgr: abfrage der version 
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [098][sub_putlong.ver]
''                              : ver - version
''                  +----------
''                  |  +------- system     
''                  |  |  +---- version    (änderungen)
''                  |  |  |  +- subversion (hinzufügungen)
''version :       $00_00_00_00
''

  sub_putlong(54)

PUB mgr_getspec                                         'cmgr: abfrage der spezifikation des chips
''funktionsgruppe               : cmgr
''funktion                      : abfrage der version und spezifikation des chips
''eingabe                       : -
''ausgabe                       : cogs - anzahl der cogs
''busprotokoll                  : [089][sub_putlong.spec]
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

  sub_putlong(CHIP_SPEC)

CON ''------------------------------------------------- SD-LAUFWERKS-FUNKTIONEN

PRI sd_mount(mode) | err                                'sdcard: sd-card mounten frida
''funktionsgruppe               : sdcard
''funktion                      : eingelegtes volume mounten
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [001][put.error]
''                              : error - fehlernummer entspr. list

  ifnot sdfat.checkPartitionMounted
    err := \sdfat.mountPartition(0,0)                     'karte mounten

    if mode == "M"                                         'frida
      bus_putchar(err)                                      'fehlerstatus senden

    ifnot err
      dmarker[RMARKER] := sdfat.getDirCluster             'root-marker setzen

      err := \sdfat.changeDirectory(string("system"))
      ifnot err
        dmarker[SMARKER] := sdfat.getDirCluster           'system-marker setzen

      sdfat.setDirCluster(dmarker[RMARKER])               'root-marker wieder aktivieren

     ' hss.sfx_play(1, @SoundFX8)                          'on-sound
  else                                                    'frida
    bus_putchar(0)                                        'frida
    outa[LED_OPEN]:=1


PRI sd_opendir | err                                    'sdcard: verzeichnis öffnen
''funktionsgruppe               : sdcard
''funktion                      : verzeichnis öffnen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [002]

  err := \sdfat.listReset
  'siglow(err)

PRI sd_nextfile | strpt                                 'sdcard: nächsten eintrag aus verzeichnis holen
''funktionsgruppe               : sdcard
''funktion                      : nächsten eintrag aus verzeichnis holen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [003][put.status=0]
''                              : [003][put.status=1][sub_putstr.fn]
''                              : status - 1 = gültiger eintrag
''                              :          0 = es folgt kein eintrag mehr
''                              : fn - verzeichniseintrag string

  strpt := \sdfat.listName                              'nächsten eintrag holen
  if strpt                                              'status senden
    bus_putchar(1)                                      'kein eintrag mehr
    sub_putstr(strpt)
  else
    bus_putchar(0)                                      'gültiger eintrag folgt

'pri sd_dirsize                                          'Anzahl Einträge im aktuellen Verzeichnis
'    sub_putlong(\sdfat.listSize)

pri sd_search   |p                                        'sucht Datei oder Verzeichnis im aktuellen Verzeichnis
    sub_getstr
    p:=\sdfat.listSearch(@tbuf)
    sub_putlong(p)

PRI sd_open  | err,modus                                'sdcard: datei öffnen
''funktionsgruppe               : sdcard
''funktion                      : eine bestehende datei öffnen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [004][get.modus][sub_getstr.fn][put.error]
''                              : modus - "A" Append, "W" Write, "R" Read
''                              : fn - name der datei
''                              : error - fehlernummer entspr. list

   modus := bus_getchar                                 'modus empfangen
   if modus>90
      modus-=32
   sub_getstr

   if modus=="A"                                        'Appendfunktion, funktioniert sonst nicht
      err := \sdfat.openFile(@tbuf, "W")                'zum schreiben öffnen
      \sdfat.setCharacterPosition(\sdfat.listSize)      'und zur letzten Position springen
   else
      err := \sdfat.openFile(@tbuf, modus)

   bus_putchar(err)                                     'ergebnis der operation senden
   outa[LED_OPEN] := 1


PRI sd_close | err                                      'sdcard: datei schließen
''funktionsgruppe               : sdcard
''funktion                      : die aktuell geöffnete datei schließen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [005][put.error]
''                              : error - fehlernummer entspr. list

  err  := \sdfat.closeFile
  'siglow(err)                                           'fehleranzeige
  bus_putchar(err)                                      'ergebnis der operation senden
  outa[LED_OPEN] := 0

PRI sd_getc | n                                         'sdcard: zeichen aus datei lesen
''funktionsgruppe               : sdcard
''funktion                      : zeichen aus datei lesen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [006][put.char]
''                              : char - gelesenes zeichen

  n := \sdfat.readCharacter
  bus_putchar(n)

PRI sd_putc                                             'sdcard: zeichen in datei schreiben
''funktionsgruppe               : sdcard
''funktion                      : zeichen in datei schreiben
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [007][get.char]
''                              : char - zu schreibendes zeichen

  \sdfat.writeCharacter(bus_getchar)


PRI sd_eof                                              'sdcard: eof abfragen
''funktionsgruppe               : sdcard
''funktion                      : eof abfragen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [030][put.eof]
''                              : eof - eof-flag

  bus_putchar(sdfat.getEOF)

PRI sd_getblk                                           'sdcard: block aus datei lesen
''funktionsgruppe               : sdcard
''funktion                      : block aus datei lesen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [008][sub_getlong.count][put.char(1)]..[put.char(count)]
''                              : count - anzahl der zu lesenden zeichen
''                              : char - gelesenes zeichen

  repeat sub_getlong
    bus_putchar(\sdfat.readCharacter)


PRI sd_putblk                                           'sdcard: block in datei schreiben
''funktionsgruppe               : sdcard
''funktion                      : block in datei schreiben
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [009][sub_getlong.count][put.char(1)]..[put.char(count)]
''                              : count - anzahl der zu schreibenden zeichen
''                              : char - zu schreibende zeichen

  repeat sub_getlong
    \sdfat.writeCharacter(bus_getchar)

PRI sd_seek | wert                                      'sdcard: zeiger in datei positionieren
''funktionsgruppe               : sdcard
''funktion                      : zeiger in datei positionieren
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [010][sub_getlong.pos]
''                              : pos - neue zeichenposition in der datei

  wert := sub_getlong
  \sdfat.setCharacterPosition(wert)

pri sd_pos
    sub_putlong(sdfat.getCharacterPosition)

pri sd_copy|laenge,m,n,cpm,psm
    cpm:=sub_getlong                         'verzeichnismarker lesen (quelle)
    psm:=sub_getlong                         'verzeichnismarker lesen (ziel)
    sub_getstr                               'dateiname lesen @tbuff

    outa[LED_OPEN]~~                         'LED an

    sdfat.setDirCluster(cpm)                 'Quellverzeichnis öffnen

    \sdfat.openFile(@tbuf, "R")              'Quelldatei öffnen
    laenge:=\sdfat.listSize                  'Dateigröße empfangen
    \sdfat.closeFile                         'Datei schließen


    m:=0
    n:=0
       repeat
       '******************** Quelldatei lesen **********************************************
              sdfat.setDirCluster(cpm)                  'Quellverzeichnis öffnen
             \sdfat.openFile(@tbuf, "R")                'Quelldatei öffnen
             \sdfat.setCharacterPosition(m)             'Position innerhalb der Datei setzen
             if laenge>4095                             '4kB Daten lesen
                \sdfat.readData(@bufrx, 4096)
                m:=\sdfat.getCharacterPosition-1        'Position innerhalb der Datei merken
             else                                       'Rest lesen
                \sdfat.readData(@bufrx, laenge)
             \sdfat.closeFile                           'Datei schließen
       '******************** Zieldatei schreiben *******************************************
             sdfat.setDirCluster(psm)                   'Zielverzeichnis öffnen
             \sdfat.openFile(@tbuf, "W")                'Zieldatei zum schreiben öffnen
             \sdfat.setCharacterPosition(m)             'Position innerhalb der Datei setzen
             if laenge>4095                             '4kB Daten schreiben
                \sdfat.writeData(@bufrx, 4096)
                n:=\sdfat.getCharacterPosition          'Position merken
             else
                \sdfat.writeData(@bufrx,laenge)   'Rest schreiben
                quit                                    'Ausstieg
             \sdfat.closeFile                           'Datei schließen
       '******************** Test auf Abbruch **********************************************
             if bus_getchar==1                          'Abbruch
                \sdfat.closeFile                        'Datei schließen
                sub_putlong(n)                          'Positionswert senden
                return                                  'Ausstieg
             sub_putlong(n)                             'Kopierfortschritt zu Regnatix senden
             laenge-=4095                               '4kB von laenge abziehen

    \sdfat.closeFile                                    'Datei schließen
    sub_putlong(-1)                                     'Aktion beendet senden

    outa[LED_OPEN]~                                     'LED aus

PRI sd_fattrib | anr,wert                               'sdcard: dateiattribute übergeben
''funktionsgruppe               : sdcard
''funktion                      : dateiattribute abfragen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [011][get.anr][sub_putlong.wert]
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

   anr := bus_getchar
   case anr
     0:  wert := \sdfat.listSize
     1:  wert := \sdfat.listCreationDay
     2:  wert := \sdfat.listCreationMonth
     3:  wert := \sdfat.listCreationYear
     4:  wert := \sdfat.listCreationSeconds
     5:  wert := \sdfat.listCreationMinutes
     6:  wert := \sdfat.listCreationHours
     7:  wert := \sdfat.listAccessDay
     8:  wert := \sdfat.listAccessMonth
     9:  wert := \sdfat.listAccessYear
     10: wert := \sdfat.listModificationDay
     11: wert := \sdfat.listModificationMonth
     12: wert := \sdfat.listModificationYear
     13: wert := \sdfat.listModificationSeconds
     14: wert := \sdfat.listModificationMinutes
     15: wert := \sdfat.listModificationHours
     16: wert := \sdfat.listIsReadOnly
     17: wert := \sdfat.listIsHidden
     18: wert := \sdfat.listIsSystem
     19: wert := \sdfat.listIsDirectory
     20: wert := \sdfat.listIsArchive
   sub_putlong(wert)

PRI sd_volname
                                          'sdcard: volumenlabel abfragen
''funktionsgruppe               : sdcard
''funktion                      : name des volumes überragen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [012][sub_putstr.volname]
''                              : volname - name des volumes
''                              : len   - länge des folgenden strings

  sub_putstr(\sdfat.listVolumeLabel)                    'label holen und senden

PRI sd_checkmounted                                     'sdcard: test ob volume gemounted ist
''funktionsgruppe               : sdcard
''funktion                      : test ob volume gemounted ist
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [013][put.flag]
''                              : flag  - 0 = unmounted, 1 mounted

  bus_putchar(\sdfat.checkPartitionMounted)

PRI sd_checkopen                                        'sdcard: test ob eine datei geöffnet ist
''funktionsgruppe               : sdcard
''funktion                      : test ob eine datei geöffnet ist
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [014][put.flag]
''                              : flag  - 0 = not open, 1 open

  bus_putchar(\sdfat.checkFileOpen)

PRI sd_checkused                                        'sdcard: anzahl der benutzten sektoren senden
''funktionsgruppe               : sdcard
''funktion                      : anzahl der benutzten sektoren senden
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [015][sub_putlong.used]
''                              : used - anzahl der benutzten sektoren

  sub_putlong(\sdfat.checkUsedSectorCount("F"))

PRI sd_checkfree                                        'sdcard: anzahl der freien sektoren senden
''funktionsgruppe               : sdcard
''funktion                      : anzahl der freien sektoren senden
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [016][sub_putlong.free]
''                              : free - anzahl der freien sektoren

  sub_putlong(\sdfat.checkFreeSectorCount("F"))

PRI sd_newfile | err                                    'sdcard: eine neue datei erzeugen
''funktionsgruppe               : sdcard
''funktion                      : eine neue datei erzeugen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [017][sub_getstr.fn][put.error]
''                              : fn - name der datei
''                              : error - fehlernummer entspr. liste

   sub_getstr
   err := \sdfat.newFile(@tbuf)
   'sighigh(err)                                         'fehleranzeige
   bus_putchar(err)                                     'ergebnis der operation senden

PRI sd_newdir | err                                     'sdcard: ein neues verzeichnis erzeugen
''funktionsgruppe               : sdcard
''funktion                      : ein neues verzeichnis erzeugen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [018][sub_getstr.fn][put.error]
''                              : fn - name des verzeichnisses
''                              : error - fehlernummer entspr. liste

   sub_getstr
   err := \sdfat.newDirectory(@tbuf)
  ' sighigh(err)                                         'fehleranzeige
   bus_putchar(err)                                     'ergebnis der operation senden

PRI sd_del | err                                        'sdcard: eine datei oder ein verzeichnis löschen
''funktionsgruppe               : sdcard
''funktion                      : eine datei oder ein verzeichnis löschen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [019][sub_getstr.fn][put.error]
''                              : fn - name des verzeichnisses oder der datei
''                              : error - fehlernummer entspr. liste

   sub_getstr
   err := \sdfat.deleteEntry(@tbuf)
  ' sighigh(err)                                         'fehleranzeige
   bus_putchar(err)                                     'ergebnis der operation senden

PRI sd_rename | err                                     'sdcard: datei oder verzeichnis umbenennen
''funktionsgruppe               : sdcard
''funktion                      : datei oder verzeichnis umbenennen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [020][sub_getstr.fn1][sub_getstr.fn2][put.error]
''                              : fn1 - alter name
''                              : fn2 - neuer name
''                              : error - fehlernummer entspr. liste

   sub_getstr                                           'fn1
   sub_getstr                                           'fn2
   err := \sdfat.renameEntry(@tbuf2,@tbuf)
  ' sighigh(err)                                         'fehleranzeige
   bus_putchar(err)                                     'ergebnis der operation senden

PRI sd_chattrib | err                                   'sdcard: attribute ändern
''funktionsgruppe               : sdcard
''funktion                      : attribute einer datei oder eines verzeichnisses ändern
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [021][sub_getstr.fn][sub_getstr.attrib][put.error]
''                              : fn - dateiname
''                              : attrib - string mit attributen
''                              : error - fehlernummer entspr. liste

  sub_getstr
  sub_getstr
  err := \sdfat.changeAttributes(@tbuf2,@tbuf)
 ' siglow(err)                                           'fehleranzeige
  bus_putchar(err)                                      'ergebnis der operation senden

PRI sd_chdir | err                                      'sdcard: verzeichnis wechseln
''funktionsgruppe               : sdcard
''funktion                      : verzeichnis wechseln
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [022][sub_getstr.fn][put.error]
''                              : fn - name des verzeichnisses
''                              : error - fehlernummer entspr. list
  sub_getstr
  err := \sdfat.changeDirectory(@tbuf)
 ' siglow(err)                                           'fehleranzeige
  bus_putchar(err)                                      'ergebnis der operation senden

PRI sd_format | err                                     'sdcard: medium formatieren
''funktionsgruppe               : sdcard
''funktion                      : medium formatieren
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [023][sub_getstr.vlabel][put.error]
''                              : vlabel - volumelabel
''                              : error - fehlernummer entspr. list

  sub_getstr
  err := \sdfat.formatPartition(0,@tbuf,0)
  'siglow(err)                                           'fehleranzeige
  bus_putchar(err)                                      'ergebnis der operation senden


PRI sd_unmount | err                                    'sdcard: medium abmelden
''funktionsgruppe               : sdcard
''funktion                      : medium abmelden
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [024][put.error]
''                              : error - fehlernummer entspr. list

  err := \sdfat.unmountPartition
  'siglow(err)                                           'fehleranzeige
  bus_putchar(err)                                      'ergebnis der operation senden
  ifnot err
    clr_dmarker
    outa[LED_OPEN]:=0                                      'LED ausschalten
  'hss.sfx_play(1, @SoundFX9)                            'off-sound

PRI sd_dmact|markernr                                   'sdcard: einen dir-marker aktivieren
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker wird aktiviert
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [025][get.dmarker][put.error]
''                              : dmarker - dir-marker
''                              : error   - fehlernummer entspr. list
  markernr := bus_getchar
  ifnot dmarker[markernr] == TRUE
    sdfat.setDirCluster(dmarker[markernr])
    bus_putchar(sdfat#err_noError)
  else
    bus_putchar(sdfat#err_noError)

{pri sddmact(markernr)

          sdfat.setDirCluster({dmarker[}markernr{]})
}
PRI sd_dmset|markernr                                   'sdcard: einen dir-marker setzen
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker mit dem aktuellen verzeichnis setzen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [026][get.dmarker]
''                              : dmarker - dir-marker

  markernr := bus_getchar
  dmarker[markernr] := sdfat.getDirCluster

PRI sd_dmget|markernr                                   'sdcard: einen dir-marker abfragen
''funktionsgruppe               : sdcard
''funktion                      : den status eines ausgewählter dir-marker abfragen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [027][get.dmarker][sub_putlong.dmstatus]
''                              : dmarker  - dir-marker
''                              : dmstatus - status des markers

  markernr := bus_getchar
  sub_putlong(dmarker[markernr])

PRI sd_dmput|markernr                                   'sdcard: einen dir-marker übertragen
''funktionsgruppe               : sdcard
''funktion                      : den status eines ausgewählter dir-marker übertragen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [029][get.dmarker][sub_getlong.dmstatus]
''                              : dmarker  - dir-marker
''                              : dmstatus - status des markers

  markernr := bus_getchar
  dmarker[markernr] := sub_getlong

PRI sd_dmclr|markernr                                   'sdcard: einen dir-marker löschen
''funktionsgruppe               : sdcard
''funktion                      : ein ausgewählter dir-marker löschen
''eingabe                       : -
''ausgabe                       : -
''busprotokoll                  : [028][get.dmarker]
''                              : dmarker - dir-marker

  markernr := bus_getchar
  dmarker[markernr] := TRUE


DAT                                                     'dummyroutine für getcogs
noteTable word 16350, 17320, 18350, 19450, 20600, 21830, 23120, 24500, 25960, 27500, 29140, 30870

                        org
'
' Entry: dummy-assemblercode fuer cogtest
'
entry                   jmp     entry                   'just loops


   


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
                      
