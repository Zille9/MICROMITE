{{        __  __ _ _         _    _
''  _   _|  \/  (_) |_ ___  | |__| (_)_   _  ___
'' | | | | |\/| | | __/ _ \ | |__| | | | | |/ _ \
'' | |_| | |  | | | ||  __/ | |  | | | |_/ |  __/
''  \__,_|_|  |_|_|\__\___| |_|  |_|_|\___/\____|
''
''  __  __               _            _____
'' |  \/  |   ___     __| |   ___    |___ /
'' | |\/| |  / _ \   / _` |  / _ \     |_ \
'' | |  | | | (_) | | (_| | |  __/    ___) |
'' |_|  |_|  \___/   \__,_|  \___|   |____/
''
'' uMite Hive-Version  AKA MODE 3 "Pixel Mode"
''

'' REGNATIX-CODE
Logbuch:

25-12-2014      -Pixel-Grafiktreiber eingebunden mit 128*96 Pixel 64 Farben
                -3762 Longs frei

}}
CON
	_xinfreq		= 5_000_000			' Quartz is 5MHz
	_clkmode		= xtal1 + pll16x		' System clock is 80MH

        '' uMite Connection Settings
        RX_PIN        = 30'6'13         '' Change I/O for connection to RX Pin.
        TX_PIN        = 31'7'12         '' Change I/O for connection to TX Pin.
        BAUD          = 38400           '' Default Baud rate

        '' Terminal Vars
        CHAR_W	      = 80
	CHAR_H	      = 30

        '' Xmodem Vars
        SOH           = 1               ' Packet Start
        STX           = 2
        EOT           = 4               ' End of Transmission
        ACK           = 6               ' Positive Acknowledgementm
        NAK           = 21              ' Negative Acknowledgement
        CAN           = 24              ' Cancel
        PAD           = 26              ' Padding at the end of the file
        RX_Buffer     = 20

'                                         +----------- Micromite
'                                         |+---------- com
'                                         || +-------- i2c
'                                         || |+------- rtc
'                                         || ||+------ lan
'                                         || |||+----- sid
'                                         || ||||+---- wav
'                                         || |||||+--- hss
'                                         || ||||||+-- bootfähig
'                                         || |||||||+- dateisystem
ADM_SPEC       = %00000000_00000000_00000010_11001011

   point       = 46                      ' point

OBJ
        ser      : "FullDuplexSerial_2k"
        'slib     : "strings2"
        ios      : "reg-ios-micro"

VAR
        byte tbuf[14]                       ' SD Vars

        byte ilen
        byte filename[16]
        byte strbuff[5]
        byte nstr[4]

        byte    expr
        long    c

        BYTE    CRC                          ' XMODEM Protocol
        BYTE    PACKET                       ' XMODEM Protocol
        BYTE    XRECV                        ' XMODEM Protocol
        BYTE    MODE                         ' XMODEM Protocol
        BYTE    RETRY                        ' XMODEM Protocol
        BYTE    XBUF[129]                    ' XMODEM Protocol
        BYTE    CBUF[129]                    ' XMODEM Protocol
        BYTE    pdata[1028]                  ' XMODEM Protocol

       '' Remember last 4 typed keys
       byte lastkey1
       byte lastkey2
       byte lastkey3
       byte lastkey4
       '' Remember last 4 keys received
       byte rec1
       byte rec2
       byte rec3
       byte rec4
       '' Variable for remote file management.
       byte filemanage [16]
       '' screen defaults

       word register

       byte localtoggle
       byte i2c

'Variablen für HIVE
  long systemdir                   'Systemverzeichnis-Marker
  byte buff[8]
  byte Play                        'Player-flag
  byte cn                          'Player-flag Abfragecounter
  byte dcf                         'dcf-flag

DAT
   SYSTEM        Byte "MICROM      ",0          'Micromite-Systemverzeichnis
   TIME          Byte "Times$=",0
   DATE          Byte "Date$=",0

PUB init

    ios.start
    ios.sdmount                                         'sd-card mounten
    activate_dirmarker(0)
    ios.sdchdir(@system)                                'in's System-Verzeichnis springen
    systemdir:=get_dirmarker                            'System-Dirmarker lesen

    activate_dirmarker(systemdir)                       'nach dem Neustart von Administra wieder ins Systemverzeichnis springen

    ios.belload(string("mode3.bel"))                'Bellatrixcode laden

    ser.start(TX_PIN,RX_PIN,%0000,BAUD)                 'serielle Schnittstelle starten
    ser.rxflush

    ios.sdunmount

    Play:=0
    cn:=0
    dcf:=0
    main

pub main|a,len,dpos,ss,sm,sh,x,y,xx,yy

   repeat  '' **** MAIN PROGRAM LOOP ****

        '' I2C command control line
        i2c :=0
        i2c := ios.i2c_get(1)'

        '--- Ist der Player aktiv, wird die Position abgefragt und bei 0 der Player gestoppt ----
        if Play==1
           cn++
           if cn>220
              cn:=0
              dpos:=ios.sid_dmppos
              if dpos<5
                 Player_stop

        case i2c

                2:  a:=ios.i2c_get(2)
                    if a<>3
                       SwitchMode(a)
                    ios.i2c_put(1,0)                                            'clear the $1e register
              180:  register:=ios.i2c_adress
                    bytemove(@filemanage, register, 13)                         'Set name to "filemanage" byte
                    ios.i2c_put(1,0)                                            'clear the $1e register
                    waitcnt(cnt + clkfreq/10)
              181:  mount
                    ios.sdopen("r",@filemanage)                                 'Open file for reading
                    len:=ios.sdfattrib(0)
                    ios.i2c_put(1,0)                                            'clear the $1e register
              182:  mount
                    ios.sdopen("w",@filemanage)                                 'Open file for writing.
                    ios.i2c_put(1,0)                                            'clear the $1e register
              183:  mount
                    ios.sdopen("a",@filemanage)                                 'Open file for append.
                    ios.i2c_put(1,0)                                            'clear the $1e register
              185:  ios.sdputc(ios.i2c_get(1))                                  'Write byte from register 1 to SD
                    ios.i2c_put(1,0)                                            'clear the $1e register
              186:  a:=ios.sdgetc                                               'Read byte SD and put in register 1
                    len--
                    if len > 0
                       ios.i2c_put(0,a)
                    else
                       'a == -1
                       ios.i2c_put(0,255)
                       'a:=0
                       ios.sdclose
                       ios.sdunmount
                       CRLF
                    ios.i2c_put(1,0)                                            'clear the $1e register
              187:
              188:
              189:  ios.sdclose
                    ios.sdunmount                                               'Close SD channel
                    ios.i2c_put(1,0)                                            'clear the $1e register
              190: ios.admreset
                   ios.belreset
                   ios.venreset
                   waitcnt(cnt+clkfreq*3)
                   reboot
              191: bootsd(string("mode2"))
              192: bootsd(string("mode3"))
              193: bootsd(string("mode4"))
              194: bootsd(string("mode5"))
              195: bootsd(string("mode6"))
              196: bootsd(string("mode7"))
              197: bootsd(string("mode8"))

              200:  register:=ios.i2c_adress
                    ios.redefine_3(byte[register][2],byte[register][3], byte[register][4],byte[register][5],byte[register][6],byte[register][7], byte[register][8],byte[register][9],byte[register][10])
                    ios.i2c_put(1,0) 'clear the $1e register

              201:  ios.plot_3(ios.i2c_get(2),ios.i2c_get(3),ios.i2c_get(4)*4)
                    ios.i2c_put(1,0) 'clear the $1e register

              202:  'register:=ios.i2c_adress
                    ios.line_3(ios.i2c_get(2),ios.i2c_get(3),ios.i2c_get(4),ios.i2c_get(5),ios.i2c_get(6)*4)
                    ios.i2c_put(1,0) 'clear the $1e register

              203:  'register:=ios.i2c_adress
                    ios.box_3(ios.i2c_get(2),ios.i2c_get(3),ios.i2c_get(4),ios.i2c_get(5),ios.i2c_get(6)*4)
                    ios.i2c_put(1,0) 'clear the $1e register

              204:  CLS
                    ser.tx(13)
                    ios.i2c_put(1,0)                                             'clear the $1e register

              205:  'Setcolors
                    ios.ChangeColor(ios.i2c_get(2)*4,ios.i2c_get(3)*4)
                    ios.i2c_put(1,0)

              209:  ios.addsprite_3(ios.i2c_get(2))
                    ios.i2c_put(1,0) 'clear the $1e register



              210:  ios.setsprite_3(ios.i2c_get(1),ios.i2c_get(2),ios.i2c_get(3))
                    ios.i2c_put(1,0) 'clear the $1e register

              211:  a:=ios.video_peek_3(ios.i2c_get(2),ios.i2c_get(3))
                    ios.i2c_put(0,a)

              230: ios.i2c_flush                                                'clear all the i2c registers
'##################### DMP-Player ##############################
              240: ios.sid_sdmpplay(@filemanage)
                   ios.i2c_put(1,0)
                   Play:=1
              241: ios.sid_dmppause
                   ios.i2c_put(1,0)
              242: ios.sid_dmpstop
                   ios.i2c_put(1,0)
                   Play:=0
                   cn:=0
'###############################################################^

        '' Check for characters from uMite and display them.
        expr := ser.rxtime(2)

        if expr <255  and expr >0
            rec1:=rec2
            rec2:=rec3
            rec3:=rec4
            rec4:=expr
            chr(expr)

        if rec1 == 27 and rec2 == 91 and rec3 == 48 and rec4 == 109  ' Detect ESC[0m
           SETCOLORS

        '' Check for input from the Keyboard.
        c := 0
        c := ios.key

        '' Convert Keyboard Scancodes to VT100 sequences.
        case c

            13:  if lastkey2 == 100 and lastkey3 == 105 and lastkey4 == 114 ' check for DIR
                    Back(3)
                    c:=0
                    dir
                 if lastkey1 == 108 and lastkey2 == 111 and lastkey3 == 97 and lastkey4 == 100 ' check for LOAD
                    Back(4)
                    c:=0
                    FILEMANAGER (string("load"),1)
                 if lastkey1 == 115 and lastkey2 == 97 and lastkey3 == 118 and lastkey4 == 101 ' check for SAVE
                    Back(4)
                    c:=0
                    FILEMANAGER (string("save"),2)
                 if lastkey1 == 98 and lastkey2 == 114 and lastkey3 == 117 and lastkey4 == 110 ' check for BRUN
                    Back(4)
                    c:=0
                    FILEMANAGER (string("BRUN"),3)
                 if lastkey2 == 98 and lastkey3 == 121 and lastkey4 == 101                     ' check for bye
                    ios.admreset
                    ios.belreset
                    ios.venreset
                    ios.stop
                    waitcnt(cnt+clkfreq*3)
                    reboot
                 if lastkey1 == 115 and lastkey2 == 121 and lastkey3 == 110 and lastkey4==99   ' check for sync (Micromite mit Hive-Zeit synchronisieren)

                    Back(4)
                    ser.str(string("TIME$="))
                    ser.tx(34)
                    ser.str(decstr(ios.gethours))
                    ser.str(string(":"))
                    ser.str(decstr(ios.getminutes))
                    ser.str(string(":"))
                    ser.str(decstr(ios.getseconds))
                    ser.tx(34)
                    ser.tx(13)

                    ser.str(string("DATE$="))
                    ser.tx(34)
                    ser.str(decstr(ios.getdate))
                    ser.str(string("-"))
                    ser.str(decstr(ios.getmonth))
                    ser.str(string("-"))
                    ser.str(decstr(ios.getyear-2000))
                    ser.tx(34)

                 if lastkey2 == 100 and lastkey3 == 99 and lastkey4 == 102    ' check for dcf (Hive-DCF ein/ausschalten )
                    back(3)
                    if dcf==0
                       ios.dcf_startup
                       dcf:=1
                    else
                       ios.dcf_down
                       dcf:=0


                 ser.tx(13)
                 lastkey1 := 0
                 lastkey2 := 0
                 lastkey3 := 0
                 lastkey4 := 0

           192:  escapesingle(68)                       'Arrow left
           193:  escapesingle(67)                       'Arrow right
           194:  escapesingle(65)                       'Arrow up
           195:  escapesingle(66)                       'Arrow down
           196:  escapesingletilda(49)                  'Home
           197:  escapesingletilda(52)                  'End
           198:  escapesingletilda(53)                  'Page up
           199:  escapesingletilda(54)                  'Page down
           200:  ser.tx(8)                              'Convert Backspace
           201:  escapesingletilda(51)                  'DEL
           202:  escapesingletilda(50)                  'Insert
           203:  ser.tx(27)                             'Convert ESC
           208:  escapedoubletilda(49,49)               'SAVE  (F1)
           209:  if Play==1
                       Player_stop
                 escapedoubletilda(49,50)               'RUN   (F2)
           210:  escapedoubletilda(49,51)               'FIND  (F3)
           211:  escapedoubletilda(49,52)               'MARK  (F4)
           212:  escapedoubletilda(49,53)               'PASTE (F5)
           213:  escapedoubletilda(49,55)               '(F6)
           214:  escapedoubletilda(49,56)               '(F7)
           215:  dir                                    '(F8)  = DIR LOCAL CONNECTED PROPELLER
                 c:=0
           216:  FILEMANAGER (string("load"),1)         '(F9)  = LOAD FILE FROM PROPELLER SD TO MICROMITE
           217:  FILEMANAGER (string("save"),2)         '(F10) = SAVE FILE FROM MICROMITE TO PROPELLER SD
           218:  FILEMANAGER (string("delete"),4)       '(F11) = DELETE FILE FROM PROPELLER SD
           219:  ser.tx(3)                              '(F12) = Break/Control-C
           466:  escapedoubletilda(50,53)               '(SHIFT-F3) = Find Again
           579:  ser.tx(3)                              'CTRL-C = Break/Control-C
           610:  FILEMANAGER (string("BRUN"),3)         'CTRL-B = BRUN Spin Binary .bin file.
           611:  ser.tx(3)                              'CTRL-C = Break/Control-C
           612:  dir                                    'CRTL-D = DIR LOCAL CONNECTED PROPELLER
                 c:=0
           620:  FILEMANAGER (string("load"),1)         'CTRL-L = LOAD FILE FROM PROPELLER SD TO MICROMITE
           624:  '                                      'CTRL-P = START THE PROPELLER SPHINX COMPILER PROCESS
           627:  FILEMANAGER (string("save"),2)         'CTRL-S = SAVE FILE FROM MICROMITE TO PROPELLER SD
           720:  'str(string("Restart..."))
                 bootsd(string("microm"))               'CTRL-F1= Neustart
           721:  bootsd(string("mode2"))                'CTRL-F2
           722:  bootsd(string("mode3"))                'CTRL-F3
           723:  bootsd(string("mode4"))                'CTRL-F4
           724:  bootsd(string("mode5"))                'CTRL-F5
           725:  bootsd(string("mode6"))                'CTRL-F6
           726:  bootsd(string("mode7"))                'CTRL-F7
           727:  bootsd(string("mode8"))                'CTRL-F8
         1..128: ser.tx(c)

            '' Send everything else that survived conversion
            '' Remember last 4 keys pressed
                   lastkey1:=lastkey2
                   lastkey2:=lastkey3
                   lastkey3:=lastkey4
                   lastkey4:=c

pub Back(n)
    repeat n
         ser.tx(8)
pub Player_stop
    ios.sid_dmpstop
    Play:=0
    cn:=0
    ios.sdunmount
Pub space (a)
  repeat a
     chr(32)
  CRLF

pub CRLF
  chr(13)
  chr(10)

pub CLS

   ios.cls

DAT     ' this list of known file extensions will be sorted with CTRL-D, "dir" or F8.
        ' feel free to change this order any way you want, or add to it.
        ' any files not on the list will be unsorted after the sorted list.

dotname byte "MDE" , 0         ' extension 0 for text color case statements above.
        byte "BAS" , 0         ' extension 1
        byte "BIN" , 0         ' extension 2
        byte "DAT" , 0
        byte "DMP" , 0
        byte "FNT" , 0
        byte "TXT" , 0
        byte "SND" , 0
        byte "SAV" , 0
        byte "SPR" , 0
        byte "SCR" , 0
        byte "PAL" , 0

types   byte 12   ' number of different file types listed above.
pub dir| stradr,n,i,dlen,dr,z,x,linelen,sp
 if Play==1
    Player_stop
 z:=15
 n:=0
 i:=1
 sp:=1
 linelen:=3
 CLS
 CRLF
 mount

 repeat x from 1 to types                                                          ' starting from 1 here hides extension 0 from dir listing.
    repeat  while (stradr:=ios.sdnext)<>0                                          'wiederholen solange stradr <> 0
         dlen:=ios.sdfattrib(0)                                                      'dateigroesse
         dr:=ios.sdfattrib(19)                                                       'Verzeichnis?

         scanstr(stradr)                                                           'dateierweiterung extrahieren

         ifnot ios.sdfattrib(17)                                                   'unsichtbare Dateien ausblenden
            if strcomp(@buff,(@dotname[x*4]))                                                   'Filter anwenden



          '################## Bildschrirmausgabe ##################################

                  ios.printchar(9) 'Tabulator für formatierte Ausgabe
                  {case x     ' extension number from DAT --> text color to display

'                    0 :     ( .MDE files are hidden, they don't need a color )
                     1 : str(string(27, "[37m"))    ' .BAS -> White
                     2 : str(string(27, "[36m"))    ' .BIN -> Yellow
                     3 : str(string(27, "[37m"))    ' .DAT -> White
                     4 : str(string(27, "[32m"))    ' .DMP -> Green
                     5 : str(string(27, "[33m"))    ' .FNT -> Cyan
                     6 : str(string(27, "[36m"))    ' .TXT -> Yellow
                     7 : str(string(27, "[37m"))    ' .SND -> White
                     8 : str(string(27, "[34m"))    ' .SAV -> Red
                     9 : str(string(27, "[33m"))    ' .SPR -> Cyan
                    10 : str(string(27, "[33m"))    ' .SCR -> Cyan
                    11 : str(string(27, "[37m"))    ' .PAL -> White
                  }
                  if sp>3
                     sp:=1
                  str(stradr)

                  ifnot dr
                        ios.print(string("  "))
                        ios.printdec(dlen)

                  linelen+=20
                  if linelen>60
                     CRLF
                     linelen:=3
                     i++

                  n++

                  if i==z                                                             '**********************************
                     CRLF
                     'str(string(27,"[34m"))
                     str(string("Press any key ..."))
                     if ios.keywait == ios#CHAR_ESC                                   'auf Taste warten, wenn ESC dann Ausstieg
                        ios.sdclose                                                   '**********************************
                        ios.sdunmount
                        abort                                                        '**********************************
                     CRLF
                     i := 0                                                           '**********************************
 'setcolors
 CRLF
 'str(string(27, "[37m"))
 str(string("Files:"))
 ios.printdec(n)
 ser.tx(8)
 ser.tx(13)

 ios.sdunmount

PRI scanstr(f) | z ,v                                                      'Dateiendung extrahieren

    repeat while strsize(f)
           if v:=byte[f++] == point                                           'bis punkt springen
              quit

   z:=0
   repeat 3                                                                     'dateiendung lesen
        v:=byte[f++]
        buff[z++] := v
   buff[z++] := 0
   return @buff

PUB bootsd (binary)
    ios.sid_dmpstop
    Combine(binary, string(".bin"))    ' .bin anhängen

     mount
     ifnot ios.sdopen("r",binary)
           ios.ldbin(binary)

PUB Combine (str1Addr, str2Addr)
{{Previously: Combine
Appends str2 to the end of str1
Combine("12345", "6789")
Output: "123456789"
string 1 (str1Addr) needs to have additional space reserved enough for string 2 to be appended.
}}
  bytemove(str1Addr + strsize(str1Addr), str2Addr, strsize(str2Addr) + 1)       ' append

  RETURN str1Addr
PUB FILEMANAGER (declaration,a)
  if Play==1
     Player_stop
  chr(13)
  c:=0
  bytefill(@filename,0,14) ' Clear filename buffer
  str(string(13,10,"Enter filename to "))
  str(declaration)
  str(string(": "))
  input(@filename,13) 'Ask for a filename to load
  if ilen == 0
    str(string(13,10,"Aborted.              "))
    ser.tx(13)
  ELSE
    case a
      1: LOAD
      2: SAVE
      3: bootsd(@filename)
      4: DELETE

PUB LOAD

    mount
    if ios.sdopen("r",@filename)
       str(string(13,10,"File not found.",13,10))
    else
      ser.str(string("XMODEM RECEIVE"))
      ser.tx(13)
      XMODEMLOAD
    ser.tx(13)
    ios.sdunmount

PUB SAVE
    mount
    if ios.sdopen("w",@filename)==0
      str(string("File exist, overwrite? y/n"))                                                            '"File exist! Overwrite? y/n"    'fragen, ob ueberschreiben
      if ios.keywait=="y"
         if ios.sddel(@filename)                                                'wenn ja, alte Datei loeschen, bei nein ueberspringen
            str(string(13,10,"Can't delete file.",13,10))
            ios.sdclose
            ios.sdunmount
            return
         ios.sdnewfile(@filename)
         ios.sdopen("w",@filename)
         ser.str(string("XMODEM SEND"))
         ser.tx(13)
         XMODEMSAVE
      else
         str(string(13,10,"Aborted !",13,10))
         ser.tx(13)
         ios.sdclose
         ios.sdunmount
         return                                                                  'datei nicht ueberschreiben

    else                                                                         'wenn die Datei noch nicht existiert
      ios.sdnewfile(@filename)
      ios.sdopen("w",@filename)
      ser.str(string("XMODEM SEND"))
      ser.tx(13)
      XMODEMSAVE


{PUB SAVE

    ser.str(string("XMODEM SEND"))
    ser.tx(13)
    XMODEMSAVE
}
PUB DELETE

  mount

  if ios.sddel(@filename)                                                                                    'ursprüngliche Datei löschen
     str(string(13,10,"Can't delete file.",13,10))
  else
     str(string(13,10,"File deleted.",13,10))
  ser.tx(13)
  ios.sdunmount

pub mount
    ios.sdmount
    activate_dirmarker(systemdir)


PUB XMODEMLOAD  | i,d,blockbar,count
    '' BASED ON: Understanding The X-Modem File Transfer Protocol
    ''           by: Em Decay
    ''
    '' This works for my project, but YMMV.  Use at own risk. :)
  bytefill(@pdata,0,1028)
  mount
  PACKET   := 0                      ' Transfer not yet started, Set Packet Number to first
  RETRY    := 0                      ' Clear Retry count
  MODE     := 0
  BLOCKBAR := 0

  REPEAT 300                         ' 40 seconds max time to wait for sender to send the file
    XRECV := ser.rx                  ' wait here for character or time-out
    'TEXT.OUT(XRECV)
     IF (XRECV == NAK)               ' If NAK is received is packet start
       MODE := 1                     ' Set file transfer mode to state 1
       QUIT


  ios.sdopen("r",@filename)
  count:=ios.sdfattrib(0)
  str(string(13,10,"Loading"))

  REPEAT WHILE MODE == 1             ' While in file transfer state

    PACKET++                         ' Increment the PACKET

    IF PACKET > 255                  ' If Packet is higher than 255
      REPEAT UNTIL PACKET < 256      ' Recalculate PACKET number
         PACKET:=PACKET-256          ' Could be wrong, but works anyway. :

    CRC := 0                         ' clear CRC for later calculation
    ser.tx(SOH)                      ' SEND SOH BYTE (Step 1) NCGbyte
    ser.tx(PACKET)                   ' SEND PACKET # (Step 2)
    ser.tx(255-PACKET)               ' SEND ONES     (Step 3)

    repeat i from 0 to 127
      d:=ios.sdgetc                  ' FETCH 128 BYTES FROM FILE
      count--
      if count==-1                   ' Check for end of file
        d:=EOT                       ' Send EOT
        MODE:=2                      ' Set Mode to Success & Bug out!

      pdata[i]:=d                    ' Position Byte in Packet
      CRC:=CRC+d                     ' Add the byte to CRC TOTAL

      ser.tx(pdata[i])               ' SEND THE PACKET (Step 4)

    repeat until CRC < 256           ' Calculate the checksum
      CRC:=CRC-256

    ser.tx(CRC)                      ' SEND THE CHECKSUM (Step 5)

    BLOCKBAR++
    str(string("."))                 ' Do something to humor the userial.

    if BLOCKBAR == 60                ' People love to be entertained.
      BLOCKBAR:=0
      chr(13)
      chr(10)
      str(string("......."))

    repeat
      i:=ser.rx                      ' WAIT FOR ACK or NAK

      if i == 43                     ' Look for + sign, meaning some sort of error
        MODE:=0                      ' Switch to mode 0, and fail the upload
        quit                         ' These 3 lines are specific to N8VEM Xmodem.

      if i==ACK
        'text.out(65)                ' display A on ACK {remarked}
        RETRY:=0                     ' Reset the retry account
        quit
      if i==NAK
        'retransmit packet
        chr(78)                 ' display N on NAK
        repeat i from 0 to 127
          ser.tx(pdata[i])           ' Send packet again
          ser.tx(CRC)                ' Send checksum again
        RETRY++                      ' Increment the retry
      if RETRY == 6                  ' Look for six concecutive fails.
        MODE:=0                      ' Set mode to indicate a fail
        quit                         ' Failed.

  ser.tx(EOT)                        ' Assume the ACK was recieved.
  'serial.tx(13)                        ' poor method, but it works.

  ios.sdclose                        ' Close data file & exit

  str(string(13,10,13,10,"Load "))
  IF (MODE == 2)                     ' Notify sender of status of file transfer
    str (string("Successful.",13,10))                                      '   Upload was a success
  ELSE
    str (string(" Failed.",13,10))
  chr(13)
  ios.sdunmount

PUB XMODEMSAVE | TCNT , blockbar,jl

  bytefill(@pdata,0,1028)
  mount
  PACKET   := 1                      ' Transfer not yet started, Set Packet Number to first
  RETRY    := 0                      ' Clear Retry count
  MODE     := 0                      ' Set Mode to zero
  BLOCKBAR := 0

  ser.rxflush
  ser.tx(NAK)                     '' send NAK to sender to inform them we are ready to receive file
  REPEAT 300                         ' 40 seconds max time to wait for sender to send the file
    'serial.tx(NAK)                   ' removed and moved above the loop from Umite version
    XRECV := ser.rxtime (500)       ' wait here for character or time-out

    IF (XRECV == SOH)                ' If character received is packet start
      MODE := 1                      ' Set file transfer mode to state 1
      QUIT                           ' exit this repeat loop

  str(string(13,10,"Saving"))
'  ios.sddel(@filename)'fsrw.popen(@filename,"w")             ' open file for write, if exists, then over write the file
'  ios.sdnewfile(@filename)
'  ios.sdopen("w",@filename)

  REPEAT WHILE MODE == 1             ' While in file transfer state
    CRC := 0                         ' clear CRC for later calculation
    XRECV := ser.rx               ' get packet number

    IF (XRECV < PACKET - 1) OR (XRECV > PACKET)  ' if packet number is in error
      MODE := 0                      ' Set to state zero
      QUIT                           ' exit this repeat loop
    ELSE
      PACKET := XRECV                ' next Packet Number

    XRECV := ser.rx               ' 1's complement Packet Number
    TCNT := 0                        ' set for start of receive buffer
    REPEAT 128                       ' Get 128 Bytes from Sender
      XBUF[TCNT] := ser.rx        ' get character from sender in put in file transfer buffer
      CRC += XBUF[TCNT++]            ' update CRC and incriment file transfer buffer

    BLOCKBAR++
    str(string("."))                 ' Do something to humor the userial.
    if BLOCKBAR == 60                ' People love to be entertained.
      BLOCKBAR:=0
      chr(13)
      chr(10)
      str(string("......"))

    XRECV := ser.rx               ' get CRC from sender
    IF (XRECV <> CRC)                ' If CRC fail
      IF (RETRY < 10)                ' and retrys are less then 10
        ser.tx(NAK)               ' Tell sender we got a bad packet
        RETRY++
        chr(120)                     ' Display a nasty X if error
        REPEAT                       ' Check for New Packet
          XRECV := ser.rx            ' get character from sender
          IF (XRECV == SOH)          ' check character for packet start
            QUIT                     ' exit this repeat loop

      ELSE                           ' Too many retrys
          MODE := 0                  ' set tranfer mode to fail
          QUIT                       ' exit this repeat loop

    ELSE                             ' Packet looks OK, lets wirte it to the SD Card
      ser.tx(ACK)                 ' Send ACK to sender
      jl:=0
      REPEAT 128
        if XBUF[jl]==0
           CBUF[jl]:=32
        else
          CBUF[jl]:=XBUF[jl]
        jl++
      ios.sdputblk(128,@CBUF)'fsrw.pwrite(@CBUF, 128)        ' first packet twice???, flag is used to filter and discard
      'bytefill(@XBUF,32,128)
      PACKET++                       ' the first xmodem packet.

      REPEAT                         ' Check were we are in the file transfer process
        XRECV := ser.rx
        IF (XRECV == EOT)            ' End of transmission ?
          ser.tx(ACK)             ' send ACK
          waitcnt(clkfreq/10 + cnt)  ' wait 100mS
          ser.tx (ACK)            ' send ACK again
          MODE := 2                  ' Set mode to completed successfully
          QUIT                       ' exit this repeat loop

        IF (XRECV == CAN)            ' Sender Cancelled transmission?
          MODE := 0                  ' Transfer aborted or incomplete
          QUIT                       ' exit this repeat loop

        IF (XRECV == SOH)            ' Next packet in the file
          QUIT
  str(string(13,10,13,10,"Save "))
  IF (MODE == 2)                     ' Notify sender of status of file transfer
    str (string("Successful",13,10))                                      '   Upload was a success
  ELSE
    str (string("Failed",13,10))                                      '   Failure in file transfer
  ios.sdclose'fsrw.pclose                        ' Close data file & exit
  chr(13)
  chr(13)
  ios.sdunmount'fsrw.unmount

PUB escapesingle(single)
    ser.tx(27) 'ESC
    ser.tx(91) '[
    ser.tx(single)
    c:=0

PUB escapesingletilda(single)
    ser.tx(27) 'ESC
    ser.tx(91) '[
    ser.tx(single)
    ser.tx(126) '~
    c:=0

PUB escapedoubletilda(doubleone,doubletwo)
    ser.tx(27) 'ESC
    ser.tx(91) '[
    ser.tx(doubleone)
    ser.tx(doubletwo)
    ser.tx(126) '~
    c:=0

PUB chr(ch)
    ios.printchar(ch)
'	command := $100 | ch
'	repeat while command

PUB str(strptr)
    ios.print(strptr)
'	repeat i from 0 to strsize(strptr)
'		chr(byte[strptr][i])

PRI textComp(str1,str2,len)
   repeat len
      if byte[str1++] <> byte[str2++]
         return false
   return true

PUB StrRight(stri,len) | i,l,z

  l:=strSize(stri)
  z:=0
  repeat i from l-len to l
    strbuff[z] := byte[@tbuf][i]
    z++
  return @strbuff

PUB input(data, size) | keystroke
   keystroke:=0
   ilen:=0
   repeat
     keystroke := ios.key

      if keystroke == $C8      ' Check for Backspace Key
        if ilen > 0
           byte[data--] := 0
           size++
           ilen--
           chr(8)
           chr(32)
           chr(8)
           keystroke := 0

      if keystroke == 13
         chr(13)
         chr(10)
         quit

      if keystroke > 10 and keystroke < 200
        if size > 1

          chr(keystroke)

          if keystroke <> 13
            byte[data++] := keystroke
            size--
            ilen++

{PUB Bootlogo

             CLS
             ''-------------------] Rick, cut on the dotted lines [-----------------------
             str(string(27,"[44m")) ''red
             space(18)
             str(string(27,"[46m")) ''yellow
             space(16)
             str(string(27,"[42m")) ''green
             space(14)
             str(string(27,"[43m")) ''cyan
             space(12)
             str(string(27,"[45m")) ''magenta
             space(10)
             setcolors
             ''----------------------------] 27 Longs [------------------------------------
             str(string(27,"[2;23H**** GEOFF GRAHAM'S MICROMITE BASIC V4.6 ****"))
             str(string(27,"[4;33H- FOR HIVE-COMPUTER V1.2 -"))
             'str(string(27,"[4;26H54k BASIC BYTES FREE"))
             str(string(27,"[7;1HREADY."))
             ser.tx(13)
}
PUB SETCOLORS

     str(string(27,"[0;1;37;41m")) '' Bright White on Blue

     ' Text Colors       Background Colors
     ' 30 Black           40 Black
     ' 31 Blue            41 Blue
     ' 32 Green           42 Green
     ' 33 Cyan            43 Cyan
     ' 34 Red             44 Red
     ' 35 Magenta         45 Magenta
     ' 36 Yellow          46 Yellow
     ' 37 White           47 White
     ' 38 Underline
     ' 1 Bright / 2 Dim

PRI SwitchMode(modenum) | i, j,numaddr

  j := 0                                                ' Set buffer ptr to 0

  repeat i from 0 to 3                                  ' Add "mode" to filename buffer
    filename[j++] := byte[@modename][i]

  numaddr := decstr(modenum)                            ' Convert mode # to ascii

  repeat i from 0 to strSize(numaddr)-1                 ' Add ascii mode # to filename buffer
    filename[j++] := byte[numaddr][i]

  'repeat i from 0 to 3                                  ' Add ".bin" to filename buffer
  '  filename[j++] := byte[@modesuffix][i]

  filename[j] := 0                                      ' Terminate filename

  bootsd(@filename)                                     ' Switch to mode

PRI decstr(value) | div, z_pad, idx

' Converts value to decimal string equivalent
' -- returns pointer to nstr
  bytefill(@nstr,0,4)
  idx := 0


  div := 100                                            ' initialize divisor
  z_pad~                                                ' clear zero-pad flag

  repeat 3
    if (value => div)                                   ' printable character?
      nstr[idx++] := (value / div + "0")                '   yes, print ASCII digit
      value //= div                                     '   update value
      z_pad~~                                           '   set zflag
    elseif z_pad or (div == 1)                          ' printing or last column?
      nstr[idx++] := "0"
    div /= 10

  return @nstr


PRI activate_dirmarker(mark)                       'USER-Marker setzen

     ios.sddmput(ios#DM_USER,mark)                 'usermarker wieder in administra setzen
     ios.sddmact(ios#DM_USER)                      'u-marker aktivieren

PRI get_dirmarker:dm                               'USER-Marker lesen

    ios.sddmset(ios#DM_USER)
    dm:=ios.sddmget(ios#DM_USER)

DAT
modename        byte    "mode"
'modesuffix      byte    ".mde"
