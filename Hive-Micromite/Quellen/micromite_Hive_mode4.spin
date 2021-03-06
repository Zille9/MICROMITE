{{        __  __ _ _         _    _
''  _   _|  \/  (_) |_ ___  | |__| (_)_   _  ___
'' | | | | |\/| | | __/ _ \ | |__| | | | | |/ _ \
'' | |_| | |  | | | ||  __/ | |  | | | |_/ |  __/
''  \__,_|_|  |_|_|\__\___| |_|  |_|_|\___/\____|
''
''  __  __               _            _  _
'' |  \/  |   ___     __| |   ___    | || |
'' | |\/| |  / _ \   / _` |  / _ \   | || |_
'' | |  | | | (_) | | (_| | |  __/   |__   _|
'' |_|  |_|  \___/   \__,_|  \___|      |_|
''
'' uMite Hive-Version  AKA MODE 4 "Sprite Mode"
''

'' REGNATIX-CODE
Logbuch:

25-12-2014      -Nostalgic-Treiber eingebunden
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
   Keyboard    = 2


'####### muss warscheinlich nach bella ########

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

OBJ
        ser       : "FullDuplexSerial_2k"
        slib     : "strings2"
        ios       : "reg-ios-micro"
        nlib    : "numbers"

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

       byte register[16]

       byte localtoggle
       'byte i2c

'Variablen für HIVE
  long systemdir                   'Systemverzeichnis-Marker
  byte buff[8]
  byte Play                        'Player-flag
  byte cn                          'Player-flag Abfragecounter
  byte dcf                         'dcf-flag

  byte Juggler

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

    ios.belload(string("mode4.bel"))                    'Bellatrixcode laden

    ser.start(TX_PIN,RX_PIN,%0000,BAUD)                 'serielle Schnittstelle starten
    ser.rxflush

    ios.sdunmount

    Play:=0
    cn:=0
    dcf:=0
    Juggler:=Keyboard
    ios.i2c_cleardone
    main


pub main|a,len,dpos,ss,sm,sh,x,y,xx,yy,i2c,i,b,y_location,x_location,vb,tile,frame,o
   ser.tx(42)
   a := cnt
   'register:=ios.i2c_adress

   frame:=-1

   repeat  '' **** MAIN PROGRAM LOOP ****

     'frame++

    { repeat i from 0 to 15

         o:=ios.get_sprattr(i)'@SprAttr+i<<4
         if frame // byte[o][Framedelay] == 0
           c:=byte[o][CurrentFrame]
           if c == byte[o][EndFrame]
             c:= byte[o][StartFrame]
           else
             c+=1
           byte[o][CurrentFrame]:=c

           ios.render_sprite_image(i,c)


         if frame // byte[o][xdelay] == 0
             byte[o][xpos] += byte[o][xinc]

         if frame // byte[o][ydelay] == 0
             byte[o][ypos] += byte[o][yinc]

         ios.render_sprite_move(i,byte[o][xpos],byte[o][ypos])

    }

        '--- Ist der Player aktiv, wird die Position abgefragt und bei 0 der Player gestoppt ----
{        if Play==1
           cn++
           if cn>220
              cn:=0
              dpos:=ios.sid_dmppos
              if dpos<5
                 Player_stop
}
       'if ios.i2c_isDone == 1
            i2c:=0
            i2c := ios.i2c_get(1)
           case i2c
                3:  'SIDcmd := ios.i2c_get(2)
                      'case SIDcmd

                                {220: key.stop
                                     waitcnt(clkfreq/100 + cnt)
                                     Juggler:= SIDcog
                                     SID.start(audior, audiol)              'Start the emulated SID chip in one cog
                                     'SID.resetRegisters                     'Reset all SID registers
                                     SID.setVolume(15)                      'Set volume to max
                                     '' Set a starting point for three voices 1 square, 2 noise, 3 sawtooth
                                     SID.setWaveform(0, SID#SQUARE)         'Set waveform type on channel1 to square wave
                                     SID.setPulseWidth(0, 1928)             'Set the pulse width on channel1 to 47:53
                                     SID.setADSR(0, 2, 5, 9, 6)             'Set Envelope on channel1
                                     SID.setWaveform(1, SID#NOISE)          'Set waveform type on channel2 to noise (drum sound)
                                     SID.setADSR(1, 0, 8, 4, 7)             'Set Envelope on channel2
                                     SID.setWaveform(2, SID#SAW)            'Set waveform type on channel3 to saw wave
                                     SID.setADSR(2, 7, 4, 9, 7)             'Set Envelope on channel3
                                     'Lp     Bp    Hp
                                     'SID.setFilterType(true, false, false)  'Enable lowpass filter
                                     'Ch1   Ch2   Ch3
                                     'SID.setFilterMask(true, false, false)  'Enable filter on the "bass channel" (channel1)
                                     'SID.setResonance(15)                   'Set the resonance value to max
                                     slave.clearDone
                                     'slave.put(1,0) 'clear the $1e register

                                221: SID.play(byte[register][3],note2freq(byte[register][4]),byte[register][5],byte[register][6],byte[register][7],byte[register][8],byte[register][9] )
                                                  'channel    'freq   'waveform  'attack  'decay   'sustain'  'release
                                     slave.put(1,0) 'clear the $1e register

                                222: SID.stop
                                     waitcnt(clkfreq/100 + cnt)
                                     key.start(keypins)
                                     Juggler := Keyboard
                                     slave.put(1,0) 'clear the $1e register

                                223: SID.setVolume(byte[register][3]) ' 0-15
                                     slave.put(1,0) 'clear the $1e register

                                224: SID.setADSR(byte[register][3],byte[register][4],byte[register][5],byte[register][6],byte[register][7])
                                     slave.clearDone
                                     'slave.put(1,0) 'clear the $1e register

                                225: SID.noteon(byte[register][3],note2freq(byte[register][4]))
                                    'channel          'frequency
                                     slave.put(1,0) 'clear the $1e register

                                226: SID.noteoff(byte[register][3])
                                     slave.put(1,0)

                                227: if byte[register][3] > 0
                                        SID.noteon(0,note2freq(byte[register][3]))
                                     if byte[register][3] > 0
                                        SID.noteon(1,note2freq(byte[register][4]))
                                     if byte[register][3] > 0
                                        SID.noteon(2,note2freq(byte[register][5]))
                                     slave.put(1,0)

                                228: SID.SetWaveForm(byte[register][3],byte[register][4]) ' Waveform
                                     'slave.put(1,0)
                                     slave.clearDone
                                229: SID.noteoff(0)
                                     SID.noteoff(1)
                                     SID.noteoff(2)
                                }
                230: ios.i2c_flush 'clear all the i2c registers

                180: LoadSprites
                     ios.i2c_clearDone

                181: LoadTiles
                     ios.i2c_clearDone

                182: LoadScreen
                     ios.i2c_clearDone

                185: 'render.set_background_origin(byte[register][2],byte[register][3])
                     ios.render_set_backround_origin(ios.i2c_get(2),ios.i2c_get(3))'byte[register][2],byte[register][3])

                190: reboot

                200: ios.write_byte_at(ios.i2c_get(2)+1,ios.i2c_get(3),ios.i2c_get(4),ios.i2c_get(5))
                     ios.i2c_clearDone

                202: ios.LoadSpr(ios.i2c_get(2),ios.i2c_get(3),ios.i2c_get(4)+16, ios.i2c_get(5)+16,ios.i2c_get(6),ios.i2c_get(7))
                     ios.i2c_clearDone

                203: ios.SetSprPos(ios.i2c_get(2),ios.i2c_get(3)+16,ios.i2c_get(4)+16)
                     ios.i2c_clearDone

                204: ios.render_sprite_hide(ios.i2c_get(2))
                     ios.i2c_clearDone

                205: i:=ios.i2c_get(2)
                     a:=4 'Start reading sprite x data at register 4
                     b:=5 'Start reading sprite y data at register 5
                     repeat until i == ios.i2c_get(3)+1
                        ios.SetSprPos(i,ios.i2c_get(a)+16,ios.i2c_get(b)+16)
                        i++
                        a:=a+2
                        b:=b+2
                     ios.i2c_clearDone


                212: ios.reset_sprites'resetallsprites
                     ios.i2c_clearDone
                    'reset all internal sprite registers to zero.

                219: ios.Animate(ios.i2c_get(2),ios.i2c_get(3),ios.i2c_get(4),ios.i2c_get(5))
                     ios.i2c_clearDone

                220: ios.MoveSpeed(ios.i2c_get(2),ios.i2c_get(3),ios.i2c_get(4),ios.i2c_get(5),ios.i2c_get(6))
                     ios.i2c_clearDone

                225: ' Get Tile
                     x_location:=ios.i2c_get(2)+1
                     y_location:=ios.i2c_get(3)
                     'vb := y_location * render#ROW_SIZE_WORD + x_location
                     'tile:= word[mapdata][vb]
                     ios.i2c_clearDone
                     ios.i2c_put(0,tile)


                230: ios.i2c_flush 'clear all the i2c registers
                                'num 0- 8, index 0-15, color
                240: ios.PaletteColorDef(ios.i2c_get(2),ios.i2c_get(3),ios.i2c_get(4))
                     ios.i2c_clearDone

                250: reboot

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

       'if Juggler:=Keyboard
       expr := ser.rxtime(2)

       if expr <255  and expr >0
            rec1:=rec2
            rec2:=rec3
            rec3:=rec4
            rec4:=expr
            chr(expr)

       c := 0
       c := ios.key

           case c

               13: ser.tx(13)
              200: ser.tx(8)                              'Convert Backspace
              203: ser.tx(27)                             'Convert ESC
              209: if Play==1
                      Player_stop
                   ser.str(string("CONTINUE",13))         '[F2] CONTINUE              'RUN   (F2)
              211: ser.str(string(13,"EDIT"))             '[F4] EDIT
                   repeat 100000
                   bootsd(string("microm"))
              219: ser.tx(3)                              '(F12) = Break/Control-C
              579: ser.tx(3)                              'CTRL-C = Break/Control-C
              610: FILEMANAGER (string("BRUN"),3)         'CTRL-B = BRUN Spin Binary .bin file.
              611: ser.tx(3)                              'CTRL-C = Break/Control-C
              720: bootsd(string("microm"))               'CTRL-F1= Neustart
              1..128: ser.tx(c)


pub LoadScreen | a,i,j,y,aa

 '' <-- 27 characters wide --> visable character starts at #2 - 29
 ''
 ''    ^
 ''    |
 ''    | 32 characters height, visable character starts at #0 - 31
 ''    |
 ''    \
   'if Juggler == Keyboard
   '   key.stop
   'if Juggler == SIDcog
   '   SID.stop

'   fsrw.start(@ioControl)
'   if \fsrw.mount(spiDO,spiClk,spiDI,spiCS) < 0
'        a:=0 ' Run screaming in circles! PANIC!
   mount
   '' Read Tiles Data into memory
   bytemove(@filename, register+2, 15)
   a:=0
'#ifdef debug
'   if \fsrw.popen(String("Demo.scr"),"r") < 0
'#else
'   if \fsrw.popen(@filename,"r") < 0
'#endif

   'This routine doesn't really care about the length of the file.  If it's shorter it'll simply not fill the page.
   y:=-1
   repeat until a == -1
      a:=ios.sdgetc
      if a == 35 'Check for # pound sign.  Beginning of actual data
         y++
         i:=2
         repeat until i == 29 'i from 2 to 29
           j:=ios.sdgetc
           if j == 13
              repeat aa from i to 29
                   'write_byte_at(aa,y,TilPalette,32)
                   ios.write_byte_at(aa,y,TilPalette,32)
              i:=28
           else
              'write_byte_at(i,y,TilPalette,j) 'palette six seems to be the correct choice for multi-color fonts
              ios.write_byte_at(i,y,TilPalette,j)
           i++

   ios.sdclose
   ios.sdunmount

   'if Juggler == Keyboard
   '   key.start(keypins)
   'if Juggler == SIDcog
   '      SID.start(audior, audiol)
   ser.tx(42)


pub LoadSprites | i,a,n,cd
   'dc:=0
   n:=0
   a:=0

   'if Juggler == Keyboard
   '   key.stop
   'if Juggler == SIDcog
   '   SID.stop
   'fsrw.start(@ioControl)
   'if \fsrw.mount(spiDO,spiClk,spiDI,spiCS) < 0
   '     a:=0 ' Run screaming in circles! PANIC!
   mount
   '' Read Sprites into memory
   bytemove(@filename, register+2, 15)

   repeat i from 0 to 15
     byte[@tbuf][i] :=0

   ios.sdopen("r",@filename)
   repeat until a == -1

     a:=ios.sdgetc

     if a == "~"
        ios.sdgetc
        ios.sdgetc
        repeat i from 1 to 15
          tbuf[0] :=ios.sdgetc
          tbuf[1] :=ios.sdgetc


          ios.sprite_palette(i,nlib.FromStr(@tbuf, nlib#hex))
          '####### byte[@Palettes][SprPalette<<4+i] := nlib.FromStr(@tbuf, nlib#hex) '###### nach bella

     if a == "#" 'Check for # sign. Begining of actual data
        repeat i from 0 to 7
          tbuf[i] :=ios.sdgetc
        ios.Longsprite(cd++,nlib.FromStr(@tbuf, nlib#hex))
        '######long[@sprites][c++] := nlib.FromStr(@tbuf, nlib#hex)'##### nach bella
        repeat i from 0 to 7
          tbuf[i] :=ios.sdgetc
        ios.Longsprite(cd++,nlib.FromStr(@tbuf, nlib#hex))
        '######long[@sprites][c++] := nlib.FromStr(@tbuf, nlib#hex)'##### nach bella
   ios.sdclose
   ios.sdunmount

   'if Juggler == Keyboard
   '   key.start(keypins)
   'if Juggler == SIDcog
   '   SID.start(audior, audiol)
   ser.tx(42)
pub LoadTiles | a,cd,i

   'if Juggler == Keyboard
   '   key.stop
   'if Juggler == SIDcog
   '   SID.stop
   'fsrw.start(@ioControl)
   'if \fsrw.mount(spiDO,spiClk,spiDI,spiCS) < 0
   '     a:=0 ' Run screaming in circles! PANIC!
   mount
   '' Read Tiles Data into memory
   bytemove(@filename, register+2, 15)

   repeat i from 0 to 15
     byte[@tbuf][i] :=0

   a:=0
   cd:=0
'#ifdef debug
'   if \fsrw.popen(String("Demo.fnt"),"r") < 0
'#else
'   if \fsrw.popen(@filename,"r") < 0
'#endif
   'fsrw.popen(string("gamemake.fnt"),"r")

   repeat until a == -1

     a:=ios.sdgetc

     if a == "~"
        ios.sdgetc
        ios.sdgetc
        repeat i from 1 to 15
          tbuf[0] :=ios.sdgetc
          tbuf[1] :=ios.sdgetc
          ios.sprite_palette(i,nlib.FromStr(@tbuf, nlib#hex))
          'byte[@Palettes][TilPalette<<4+i] := nlib.FromStr(@tbuf, nlib#hex)

     if a == "#" 'Check for # sign. Begining of actual data
        repeat i from 0 to 7
          tbuf[i] :=ios.sdgetc
        ios.Longtiles(cd++,nlib.FromStr(@tbuf, nlib#hex))
        'long[@tiles][c++] := nlib.FromStr(@tbuf, nlib#hex)

   ios.sdclose
   ios.sdunmount
   'if Juggler == Keyboard
   '   key.start(keypins)
   'if Juggler == SIDcog
   '   SID.start(audior, audiol)
   ser.tx(42)

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

     if slib.strpos(binary, string(".bin"),0) == -1 and slib.strpos(binary, string(".mde"),0) == -1
        slib.Concatenate(binary, string(".bin"))

     mount
     ifnot ios.sdopen("r",binary)
           ios.ldbin(binary)

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

    ser.str(string("XMODEM SEND"))
    ser.tx(13)
    XMODEMSAVE

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
  ios.sddel(@filename)'fsrw.popen(@filename,"w")             ' open file for write, if exists, then over write the file
  ios.sdnewfile(@filename)
  ios.sdopen("w",@filename)

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

{PRI decstr(value) | div, z_pad, idx

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
}

PRI activate_dirmarker(mark)                       'USER-Marker setzen

     ios.sddmput(ios#DM_USER,mark)                 'usermarker wieder in administra setzen
     ios.sddmact(ios#DM_USER)                      'u-marker aktivieren

PRI get_dirmarker:dm                               'USER-Marker lesen

    ios.sddmset(ios#DM_USER)
    dm:=ios.sddmget(ios#DM_USER)

DAT
modename        byte    "mode"
modesuffix      byte    ".mde"
