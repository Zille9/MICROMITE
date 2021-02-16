'********************************************
'********************************************
'           EEPROM-Library v0.81
' -----------------------------------------
' by twofingers 09-2014 at TBS
' with parts from MMBasic Library
' for AT24V32 (32kBit EEPROM)
' at DS3231 or DS1307 RTC-Modules etc.
' MMBasic 4.5 for Maximite/Duinomite
'------------------------------------------
' eeWrite$: writes a string to address
' eeRead$ : reads a string from address
' eeGet$  : returns a amount of bytes from address
' eeWriteB: writes a 1 byte to address
' eeReadB : reads 1 byte from address
'   address may be between 0 to 4095
'
' eeSaveF : writes a 32 bit floatinpoint number
' eeSaveF4: writes a 32 bit floatinpoint number
'      at EEPROM addresses divisible by 4
'      (faster then eeSaveF)
' eeLoadF : reads a 32 bit floatinpoint number
'   back from EEPROM using PEEK and POKE
'   needs eeWriteB and eeReadB
'
' eeErase : deletes the whole eeprom w. verify
'
' eeDump  : shows content of eeprom or parts
' eeMon   : displays whole eeprom content (scroll)
'
' I2CPROM (I2C address of your EEPROM)
' must always be defined globally
'-------------------------------------------
'
' Remark: A check for defective Bytes
' has a latency of ~1 sec !!
' Therefore one second should be elapsed after
' each write event and then follow a read/compare,
' if a verify is required.
'
'-------------------------------------------
'
' This code may be freely distributed and
' changed. Provided AS IS without any warranty.
' Use it at your own risk.
'********************************************
'********************************************




'#######################################
' Demonstration code
'--------------------
I2CPROM = &H57 'I2CAdress of EEPROM
               'if unknown please use the i2CSanner
               'or the damn datasheet

Cls
Print "WARNING: THIS DEMO WILL ERASE YOUR EEPROM!":Print
waitkey"press any key for eeSaveF4 demonstration (or CTRL+C to abort)"
Print "writing 1024 floats ...  (takes 5s)"

For i = 0 To 1023 'fill with 32 bit floats (= 4 bytes)
  eeSaveF4(i*4,i+Pi/10)
Next i

waitkey"press any key for eeLoadF (reading back)"

Cls
For i = 0 To 1023
  Print eeLoadF(i*4)
Next i


' Dump demos
waitkey"press any key for eeDump 3800,100"
Cls
eeDump 3800,100

waitkey"press any key for eeDump 3990"
Cls
eeDump 3500

waitkey"press any key for eeDump"
Cls
Print "reading (4096 bytes)... (4s)"
eeDump

waitkey"press any key for eeMon"
Cls
eeMon
Cls
waitkey"press any key for eeErase"
Cls
eeErase

waitkey"press any key for eeMon"
Cls
eeMon
Cls
l1:
waitkey"press any key for eeWrite$ + eeRead$ + eeGet$"
Cls
Print "Writing at 0 'THE BACKSHED DEMO'"
eeWrite$ 0,"THE BACKSHED DEMO"

For i = 1 To 25
  a$=a$+"ABCDFEGHIJ"
Next i
A$=A$+"ABCDF"
Print "Writing at 256: "A$:Print:Print
eeWrite$ 256,A$
Print:Print "reading back:"
Print eeRead$(256)
Print
Print eeGet$(0,17)

waitkey"press any key for eeMon"

eeMon
Cls
waitkey"press any key for eeWriteB + eeReadB"

For i = 0 To 255
  eeWriteB i,i
Next i


For i = 1 To 255
  Print eeReadB(i)
Next i

waitkey"press any key for eeMon"

eeMon
Cls
waitkey"End of demonstration! Press any key."

'--------------------------
' End of demonstration code
'#######################################





'**********************************
' Saves a floatingp. var (v) to AT24C32
' similar to eeSaveF but faster
'
' address should be divisible
' by 4 without a remainder
' (page mode roll over trouble)
' Plz obey mmbasic limits for
' floating point numbers otherwise
' U will get a serious memory error!
'**********************************
Sub eeSaveF4 (address, v)
  Local fill(6),i,v1
  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End

  If address Mod 4 Then
     Print "Error: address should be divisible without a remainder"
     End
  EndIf

  I2C open 100,100 'ENABLE I2C

  fill(0)=Int(address/256) 'MSB
  fill(1)=address Mod 256  'LSB
  For i = 0 To 3: fill(i+2)=Peek(VAR v,i):Next i

  I2C write I2CPROM, 0, 6, fill(0)
  If MM.I2C <>0 Then Print "Error(1)! 1=NAK 2=TIMEOUT"; MM.I2C: End
  Pause 1

  I2C close

End Sub


'******************************
Sub eeSaveF (address, v)
' Saves a floatingp. var to AT24C32
'******************************
  Local i
  For i = 0 To 3
    eeWriteB address+i, Peek(VAR v,i)
  Next i
End Sub


'******************************
Function eeLoadF (address)
' Load a floatingp. var from AT24C32
' Attention:
' never use this for strings!
'******************************
  Local i
  For i = 0 To 3
    Poke VAR eeLoadF,i, eeReadB(address+i)
  Next i
Function Sub


'******************************
Sub eeWriteB (address, byte)
' Write a byte (0-255) to AT24C32
'******************************
  Local msb, lsb
  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End

  I2C open 100,100 'ENABLE I2C
  msb=Int(address/256) 'MSB
  lsb=address Mod 256  'LSB

  I2C write I2CPROM, 0, 3, msb, lsb, byte
  Pause 1
  If MM.I2C <>0 Then Print "Error! 1=NAK 2=TIMEOUT"; MM.I2C: End
  I2C close
  If debug Then Print byte;" written into EEPROM."
End Sub


'******************************
Function eeReadB (address)
' Read a byte (0-255) from AT24C32
'******************************
  Local msb, lsb

  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End

  I2C open 100,100 'ENABLE I2C
  msb=Int(address/256) 'MSB
  lsb=address Mod 256  'LSB

  I2C write I2CPROM, 0,2,msb,lsb
  I2C read I2CPROM, 0,1,eeReadB

  If MM.I2C <>0 Then Print "ERROR! 1=NAK 2=TIMEOUT"; MM.I2C:eeReadN=-1:End
  I2C close

End Function


'******************************
Sub eeWrite$ (address, text$)
' Writes a string to AT24C32
'******************************
Local a,x,msb,lsb,PByte

  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End

  a=0

  If Len(text$)+address>4095 Then Print "Error: Address too high!":End

  I2C open 100,100 'ENABLE I2C
  For x= address To address+Len(text$) 'writes a 0-byte at the end!
    a=a+1
    msb=Int(x/256) 'MSB
    lsb=x Mod 256  'LSB

    PByte=0:If a<256 Then PByte=Asc(Mid$(text$,a,1))

    I2C write I2CPROM, 0, 3, msb, lsb, PByte
    If MM.I2C <>0 Then Print "Error! 1=NAK 2=TIMEOUT"; MM.I2C: End
    Pause 1
  Next x
  I2C close
  If debug Then
    Print "The string "+Chr$(34);:Print text$;
    Print Chr$(34)+" was successfully written at address"address" into EEPROM."
  EndIf
End Sub


'******************************
Function eeGet$ (address, amount)
' Returning a amount of bytes from
' address of an AT24C32.
'******************************
Local x,msb,lsb,tmp

  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End

  eeGet$=""

  If address>4095 Then Print "Error: Address too high!":End
  If amount>255 Then Print "Error: String would be too long!":End

  I2C open 100,100 'ENABLE I2C
  For x= address To address+amount-1

    msb=Int(x/256) 'MSB
    lsb=x Mod 256  'LSB

    I2C write I2CPROM, 0,2,msb,lsb
    I2C read I2CPROM, 0,1,tmp

    If MM.I2C <>0 Then Print "Error! 1=NAK 2=TIMEOUT"; MM.I2C: End
    eeGet$=eeGet$+Chr$(tmp)

  Next x
  I2C close
End Function


'******************************
Function eeRead$ (address)
' Reads a zero-terminated string from AT24C32
'******************************
  Local msb,lsb,tmp
  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End

  eeRead$=""

  If address>4094 Then Print "Error: Address too high! (valid: 0-4094)":End

  I2C open 100,100 'ENABLE I2C

  Do

    msb=Int(address/256) 'MSB
    lsb=address Mod 256  'LSB

    I2C write I2CPROM, 0,2,msb,lsb
    I2C read I2CPROM, 0,1,tmp

    If MM.I2C <>0 Then Print "Error! 1=NAK 2=TIMEOUT"; MM.I2C: End
    If tmp=0 Then Exit 'leave loop
    eeRead$=eeRead$+Chr$(tmp)
    address=address+1

  Loop While Len(eeRead$)=<255

  I2C close
Function end


'**************************************
' ERASE WHOLE EEPROM (fill with zero)
' Warning:
' EEPROM has a limited endurance
'**************************************
Sub eeErase
  Local i,K1,eePage,MSB,LSB,xfill(34)
  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End
  K=&H00 'zero value or something else - K=&HAA, K=&H55 ... K=&HFF
  Timer=0

  If GetKey$("Ready to erase EEPROM at &H"+Hex$(I2CPROM)+"? <y/n>")<>"y" Then
    Print "EEPROM erase aborted!"
    End Sub
  Else
    Print "EEPROM erase confirmed!"
  EndIf

  For i = 0 To 31: Xfill(i+2)=K: Next i

  Print "Erasing ";:vpos=MM.VPos:hpos=MM.HPos
  I2C open 100,100 'ENABLE I2C

  For eePage = 0 To &H7F '&H7F = 128 Pages a 32 bytes = 4096 bytes
    MSB=Int(eePage/8)
    LSB=(eePage-MSB*8)*32
    Xfill(0)=MSB
    Xfill(1)=LSB
    I2C write I2CPROM, 0, 34, Xfill(0)
    If MM.I2C <>0 Then Print "Error(1)! 1=NAK 2=TIMEOUT"; MM.I2C: End
    Pause 1
    Print @(HPos+MSB*4,VPos)".";' progressbar
  Next eePage

    'verify
  For eePage = 0 To &H7F '&H7F = 128 * 32 bytes = 4096 bytes
    MSB=Int(eePage/8)
    LSB=(eePage-MSB*8)*32

    I2C write I2CPROM,0,2,MSB,LSB ' set read address
    For i=0 To 31
      I2C read I2CPROM,0,1,K1
      If MM.I2C <>0 Then Print "Error(2)! 1=NAK 2=TIMEOUT"; MM.I2C: End
      If K<>K1 Then
        Print:Print "Verify error! at"; MSB*256+LSB+i;
        Print "   Byte: ";K " <>" K1;" - "Bin$(k)" <> "Bin$(K1)
        End
      EndIf
    Next i
    Print @(HPos+MSB*4,VPos)":";' progressbar
  Next eePage

  I2C close
  Print:Print "SUCCESS: EEPROM HAS BEEN ERASED!"
  Print "Elapsed time: "Timer"ms"
End Sub


'*******************************************
' DUMP EEPROM
' Shows content from AT24C32
' will be used from eeMon or separatly
'
' Syntax:
' eeDump
' Displays whole content of EEPROM, byte 0-4095
'
' eeDump start
' Displays partial content of EEPROM, byte start-4095
'
' eeDump start,amount
' Displays partial content of EEPROM,
' byte start to start+amount
'*******************************************
Sub eeDump start,amount
  Local FromByteNr, msb, lsb, i, RTCBUFF(4096)
  ' I2CPROM=&H57 ' 24C32-DS3231
  If I2CPROM = 0 Then Print "Error: Please define I2CPROM globally": End

  If amount=0 Then amount=4095

  FromByteNr=Int(start/16)*16
  amount=amount+start-FromByteNr:If amount+FromByteNr>4095 Then amount=4095-FromByteNr

  If amount<1 Then
     Print "Error: Nothing to display. Amount: " amount,FromByteNr
     End Sub
  EndIf

  amount=(Int((amount+15)/16))*16
  ' fill buffer
  I2C open 100,100 'ENABLE I2C

  ' reading EEPROM
  For i = FromByteNr To FromByteNr+amount
    msb=Int(i/256) 'MSB
    lsb=i Mod 256  'LSB
    I2C write I2CPROM, 0,2,msb,lsb
    I2C read I2CPROM, 0,1,RTCBUFF(msb*256+lsb)
    If MM.I2C <>0 Then Print "ERROR! 1=NAK 2=TIMEOUT"; MM.I2C,i:End
  Next i

  I2C close

  ' display buffer content
  For I=FromByteNr To FromByteNr+amount-1 Step 16' 4095 Step 16
    Print "Byte ";Format$(I,"%4g");" ||";
    For y = 0 To 15
      Print Right$("0"+Hex$(RTCBUFF(I+y)),2);"|";
    Next y
    Print "|";
    For y = 0 To 15
      If RTCBUFF(I+y) >=32 And RTCBUFF(I+y)<=126 Then ' show ascii only
        C$=Chr$(RTCBUFF(I+y))
      Else
        C$=" "
      EndIf
      Print C$;
    Next y
    Print "|"
    'waitkey"press any key"
  Next I

End Sub


'*************************************
Sub eeMon 'eeMonitor
' Shows content of EEPROM
' You can navigate and scroll through
'*************************************
Local i, upArrow,dnArrow,pageUp,pageDn,LinesPerScreen,KeyText$
Local EndKey, HomeKey, EscKey

 upArrow=128
 dnArrow=129
 HomeKey=134
 EndKey =135
 pageUp =136
 pageDn =137
 EscKey =27
 MsgPos =62*6

 LinesPerScreen=MM.VRes/12-3
 KeyText$="Control: Cursor up/down, Page up/down, End, Home, Esc"

 Cls
 Font #1,,1
 Print @(60,0)" <EEPROM AT24C32 DUMP &H"+Hex$(I2CPROM)+"> "
 Font #1,,0
 For i = 0 To LinesPerScreen
   eedump i *16,16
 Next i
 i=i-1

 Print @((MM.HRes-Len(KeyText$)*6)/2,MM.VRes-12) KeyText$

 Do
   Print @(MsgPos,0) Space$(20) 'clear error message

   Do:AscKey=KeyDown:Loop While AscKey=0

   If AscKey = dnArrow And i < 255 Then
       scrollup
       i=i+1
       Print @(0,MM.VRes-24);:eedump i *16,16
     Else
       If AscKey = dnArrow Then
          PrintFlash MsgPos," UPPER LIMIT! "
       EndIf
   EndIf

   If AscKey = upArrow And i > LinesPerScreen Then
       scrolldn
       i=i-1
       Print @(0,12);:eedump i *16-33*16,16
   Else
       If AscKey = upArrow Then
          PrintFlash MsgPos," LOWER LIMIT! "
       EndIf
   EndIf

   If AscKey = PageUp And i > LinesPerScreen Then
     offset=i-LinesPerScreen*2-1
     If offset<0 Then offset = 0
     For i = offset To offset+LinesPerScreen
       eedump i *16,16
     Next i
     i=i-1
   Else
     If AscKey = PageUp Then
        PrintFlash MsgPos," LOWER LIMIT! "
     EndIf
   EndIf

   If AscKey = PageDn And i < 255 Then
     offset=i+1
     If offset+LinesPerScreen>=255 Then offset = 255-LinesPerScreen
     For i = offset To offset+LinesPerScreen
       eedump i *16,16
     Next i
     i=i-1
   Else
     If AscKey = PageDn Then
        PrintFlash MsgPos," UPPER LIMIT! "
     EndIf
   EndIf

   If AscKey = HomeKey And i > LinesPerScreen Then
     offset=0
     For i = offset To offset+LinesPerScreen
       eedump i *16,16
     Next i
     i=i-1
   EndIf

   If AscKey = EndKey And i < 255-LinesPerScreen Then
     offset=255-LinesPerScreen
     For i = offset To offset+LinesPerScreen
       eedump i *16,16
     Next i
     i=i-1
   EndIf

   If AscKey = EscKey Then Exit

 Loop
End Sub
'********************* END eeMon *************************



Sub PrintFlash MsgPos,text$
  Local i,revers
  i = 4: revers = 0
  Do
    Font #1,,revers
    Print @(MsgPos,0) text$
    Pause 200
    i=i-1
    revers=Not revers
  Loop While i>0
  Font #1,,0
End Sub


Sub scrollup '36*12 Zeilen = 432
 'blit x,y,x1,y1,w,h
  BLIT 0,24,0,12,MM.HRes,MM.VRes-36
End Sub

Sub scrolldn
  BLIT 0,12,0,24,MM.HRes,MM.VRes-36
End Sub


' wait for any key, returns the keyChar$
Function GetKey$ prompt$
  Local k
  k = KeyDown
  If prompt$<>"" Then Print prompt$
  Do:GetKey$=Inkey$:Loop While GetKey$=""
End Function


' wait for any key
Sub WaitKey prompt$
  Local k
  k=KeyDown
  If prompt$<>"" Then Print prompt$
  Do:Loop While Inkey$=""
End Sub


'-----------------------------------------------------------

'**********************************
'           I2C-Scanner
' scans I2C-Bus for I2C addresses
' MM-Basic 4.5 / Maximite/Duinomite
' by twofingers 21-08-2014 on TBS
'**********************************
Sub I2CScanner
Local found, i

 found=0
 Cls
 Print "I2C-Scanner from Adr. 8-119":Print:Print

For i = &h08 To &h77 ' gueltige I2C-Adressen von 8-119
 I2C open 100, 1000  ' i2c enable 100kHz, 1000ms timeout
 I2C read i, 0, 1, temp

 Print i;">"; MM.I2C " ";
 If MM.I2C = 0 Then
   Print:Print:Print "Found I2C-Address at ";  i; " ("dec2hex$(i)+")"
   found=1
 EndIf
 I2C close            ' i2c disable

 Next i
 If found = 0 Then Print:Print:Print "NO I2C-Address found!"
End Sub

Function dec2hex$(number) ' uused by I2C-Scanner
  dec2hex$ = "&H"+ Hex$(number)
End Function

'***********************************************************

Sub cls
  I2C open 400,100
  I2C write &h42,0,2,1,204
  Pause 100
  I2C close
End Sub                                            