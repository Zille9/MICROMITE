''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This is a demonstration server program running on the Micromite and
' using the ESP8266 module to serve up a WEB page.  Geoff Graham, Nov 2014
'
' This server will run on all versions of the Micromite firmware however
' support for the DHT22 temperature/humidity sensor is only present in
' version 4.6 of MMBasic for the Micromite MkII.
' For details on the Micromite go to:  http://geoffg.net/micromite.html
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' The following four constants should be edited to reflect your requirements
SSID$ = "DIABLO"            ' Replace SSID with the name of your WiFi network
Passwd$ = "zillesoftgmbh"        ' Replace passwd with the password to your network
Timeout = 20000           ' Error timeout in milliseconds
echo = 0                  ' Set this to non zero to see all communications

' Define an array to record the server activity (ie, statistics)
StatSize = 40
Dim Stats$(StatSize)
shead = 0

' Some housekeeping - autorun on, watchdog on and setup the reset output
Option autorun on
WatchDog 60 * 1000
Pin(2) = 0
SetPin 2, dout

Pause 1000    ' Let everything settle
VAR RESTORE   ' Restore the connection count (for the statistics)
'RTC GETTIME   ' Get the current time

' Setup the automatic timer events
' Timer one will get the time from the RTC every four hours
' Timer two will get the temperature and humidity every two minutes
' Timer three will save the connection count once a day (in case
' of power failure)
SetTick 4 * 60 * 60 * 1000, GetRtcTime, 1
SetTick 2 * 60 * 1000, GetDHT22, 2
SetTick 24 * 60 * 60 * 1000, SaveVars, 3

' Open communications with the ESP8266 module
Open "COM1:115200, 1024" As #1


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This is the restart point.  If the ESP8266 module has crashed the
' timeout will cause us to jump back to here
ReTryWEB:
WatchDog 240 * 1000  ' Restart the BASIC program in the event of a crash
error = 0            ' Clear the error flag

' Close the serial port so that it will go to high impedance.  This will
' protect the Rx input to the ESP8266 when it is powered down.
' Then power down the module for one second and re open the serial port
Close #1
Pin(14) = 0 : Pause 1000 : Pin(14) = 1 : Pause 1000
Open "COM1:115200, 1024" As #1

' Record this event in the log and display it on the console
Stats$(shead) = "Starting the server at " + Date$ + " " + Time$
Print : Print Stats$(shead)
shead = (shead + 1) Mod StatSize

' Check that the ESP8266 module is alive
SendCmd "AT", "OK"
If error GoTo ReTryWEB

' set the module to client and AP mode and reset it
Print #1, "AT+CWMODE=1"
Pause 50
SendCmd "AT+RST", "chksum 0xe1"
ClearBuffer
' Log into the network and setup the server function
Print "Found the ESP8266.  Firmware version " + GetVer$()
SendCmd "AT+CWJAP="+Chr$(34)+SSID$+Chr$(34)+","+Chr$(34)+Passwd$+Chr$(34), "OK"
Print "Connected to " + SSID$ + ". IP Address " + GetAddr$()
SendCmd "AT+CIPMUX=1", "OK"
SendCmd "AT+CIPSERVER=1,80", "OK"
If error GoTo ReTryWEB

Print "WEB server started"
s$ = ""
Timer = 0

' This is the main server loop.
' The program looks for someone connectiong to the server (a line from the
' module starting with +IPD).  It will then get the channel number (in case
' of multiple connections) then send the web page.
'
' When finished it will close the channel and check is there is another
' connection and if there is it will loop to satisify that request.
' If there is no activity for five minutes the program will check that the
' module is alive by sending an AT command.
Do
  ' The watchdog is used to detect if the program has crashed
  WatchDog 240 * 1000
  ' Accumulate characters in s$ until a carriage return is received
  ' This includes resetting the timer which is used to detect no activity
  ' and also trimming the lenght of the input if it is too long.
  a$ = Input$(1, #1)
  If a$ <> "" Then
    Timer = 0
    If echo Then Print a$;
  EndIf
  If Len(s$) >= 254 Then s$ = Right$(s$, 125)
  If Asc(a$) >= 32 Then s$ = s$ + a$

  If Asc(a$) = 13 Then
    ' We have a carriage return.  Check to see if it is a request for a WEB page
    If Left$(s$, 5) = "+IPD," And (Instr(s$, "GET / ") > 1 Or Instr(s$, "GET /stats ") > 1) Then
       SendStats = Instr(s$, "GET /stats ")   ' SendStats is a flag to send the stats only
       channel$ = Mid$(s$, 6, 1)              ' Get the channel number for this connection
       Pause 10                               ' Let the rest of the data arrive
       Do
         s$ = GetLine$()
         If error Then GoTo ReTryWEB
       Loop Until s$ = "OK"                   ' OK means the end of the messages from the module

       ' We can loop back to here if another connection comes in while we are sending the page
       Do
         ' Record the connection in the statistics and print on the console
         count = count + 1                    ' Count is the number of connections
         Stats$(shead) = Date$ + " " + Time$ + " Connection number " + Str$(count) + " from " + GetClientIP$(channel$)
         If SendStats Then Stats$(shead) = Stats$(shead) + " for stats"
         Print Stats$(shead)
         shead = (shead + 1) Mod StatSize

         ' Send the data requested.
         ' Which can be the statistics (garden.geoffg.net/stats) or the normal page
         If SendStats Then
            ServeStats
         Else
            ServePage
         EndIf

         ' close the connection
         SendCmd "AT+CIPCLOSE=" + channel$, "OK"
         If error Then GoTo ReTryWEB

         ' Use the "get status" command to see if there is another connection
         ' and retreive its channel number
         channel$ = ""
         ClearBuffer
         Print #1, "AT+CIPSTATUS"
         Do
           s$ = GetLine$()
           If error Then GoTo ReTryWEB
           If echo Then Print s$
           If Instr(s$, "+CIPSTATUS:") = 1 Then
            channel$ = Mid$(s$, 12, 1)
             ClearBuffer
             s$ = "OK"
           EndIf
         Loop Until s$ = "OK"
       ' keep looping while we have a connection to process
       Loop While channel$ <> ""
    EndIf

  s$ = ""
  EndIf

  ' Every five minutes with no activity send an AT command
  ' and check that the module responds with OK
  If Timer > 5 * 60 * 1000 Then
    SendCmd "AT", "OK"
    If error Then GoTo ReTryWEB
    ClearBuffer
    Timer = 0
  EndIf

Loop     ' Keep looking for connections to the server
End


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This sub is called every four hours and is used to correct the Micromite's
' internal clock
Sub GetRtcTime
  RTC GETTIME
End Sub


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This sub gets the temperature and humidity.
' Support for the DHT22 is new in MMBasic V4.6 for the Micromite MkII
Sub GetDHT22
Print "temp" '  DHT22 16, temp, humid
End Sub


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This sub is called every 24 hours and saves the connection count so that
' we can restore it in case of a power failure
Sub SaveVars
  VAR SAVE count
End Sub



''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This sub sends the main WEB page
Sub ServePage
  ServeLine "<TITLE>Micromite WiFi Server</TITLE>"
  ServeLine "<H3>Welcome to the Micromite Garden Webserver</H3><BR>"
  ServeLine "You are visitor number: " + Str$(count) + "<BR><BR>"
  ServeLine "The Micromite time is " + Time$
  ServeLine " and the date is " + Date$ + "<BR><BR>"
  ServeLine "The temperature in the garden is " + Str$(temp) + "&deg;C"
  ServeLine " and the humidity is " + Str$(humid) + "%<BR><BR>"
  ServeLine "The MMBasic program running the server can be downloaded from "
  ServeLine "<a href=" + Chr$(34) + "http://geoffg.net/Downloads/ServerSrc.zip" + Chr$(34) + ">here</a>.<BR>"

End Sub



''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This sub sends the statistics WEB page
Sub ServeStats
  Local i
  ServeLine "<TITLE>WiFi Server Statistics</TITLE>"
  ServeLine "Number of connections: " + Str$(count) + "<BR><BR>"
  i = shead
  Do
    If Stats$(i) <> "" Then ServeLine Stats$(i) + "<BR>"
    i = (i + 1) Mod StatSize
  Loop While i <> shead
End Sub


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This sub sends a single line of the WEB page
' It uses the global channel$ to identify the connection
Sub ServeLine lin$
  If error Then Exit Sub
  Print #1, "AT+CIPSEND=" + channel$ + "," + Str$(Len(lin$)+2)
  Pause 100
  SendCmd lin$, "SEND OK"
End Sub



''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This is a general purpose sub which will send a command and check
' for the correct response
Sub SendCmd cmd$, response$
  Local InputStr$
  If error Then Exit Sub
  ClearBuffer
  Print #1, cmd$
  Do
    InputStr$ = GetLine$()
 '  Print "From ESP ";InputStr$+" required ";response$
  Loop Until Instr(InputStr$, response$) > 0 Or error
End Sub


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This will get the version number of the firmware running on the module
Function GetVer$()
  Local s$, i
  If error Then Exit Function
  ClearBuffer
  Print #1, "AT+GMR"
  For i = 1 To 3
    s$ = GetLine$()
    If error Then Exit For
    If echo Then Print s$
  Next i
  GetVer$ = s$
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This will get the IP address of a specific connection
' c$ is an ASCII character representing the channel number
Function GetClientIP$(c$)
  Local s$
  If error Then Exit Function
  GetClientIP$ = "unknown"
  ClearBuffer
  Print #1, "AT+CIPSTATUS"
  Do
    s$ = GetLine$()
    If error Then Exit Do
    If echo Then Print s$
    If Instr(s$, "+CIPSTATUS:" + c$) = 1 Then
      s$ = Mid$(s$, Instr(s$, ",") + 1)
      s$ = Mid$(s$, Instr(s$, ",") + 2)
      GetClientIP$ = Left$(s$, Instr(s$, ",") - 2)
    EndIf
  Loop Until s$ = "OK"
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This will get the IP address of the module
' After connecting to the access point it can take several seconds for the
' command to complete.  This sub will keep trying to get the address and will
' only return when it has it (this signifies that the connection is made).
Function GetAddr$()
  Local s$, i, j
  If error Then Exit Function
  For i = 1 To 20
    ClearBuffer
    Print #1, "AT+CIFSR"
    For j = 1 To 3
      s$ = GetLine$()
      If error Then Exit For
      If echo Then Print s$
    Next j
    If Len(s$) > 5 Or error Then Exit For
    Pause 1000
  Next i
  GetAddr$ = s$
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' clear the serial input buffer of any junk
Sub ClearBuffer
  Do : Loop Until Input$(255, #1) = ""
End Sub


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Get a line of text from the module
' This function can work with lines that are longer than the Micromite's
' maximum string length of 255 characters (unlike LINE INPUT)
Function GetLine$()
  Local s$, c$
  Timer = 0
  Do
    c$ = Input$(1, #1)
    If echo Then Print c$;
    If Asc(c$) = 13 Or Len(s$) >= 254 Then
      GetLine$ = s$
    Else
      If Asc(c$) >= 32 Then s$ = s$ + c$
    EndIf
    If Timer > Timeout Then error = 1
  Loop Until Asc(c$) = 13 Or Len(s$) >= 254 Or error
End Function


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' This function is a simple terminal for testing commands on the module.
' It can be run at the MMBasic command prompt just by entering its name.
' For example:
' > Terminal
Sub Terminal
  Local c$
  Open "Com1:115200, 1024" As #1
  Do
    Print Input$(1, #1);
    Print #1, Inkey$;
  Loop
End Sub                                               