' The following four constants should be edited to reflect your requirements
SSID$ = "DIABLO"           ' Replace SSID with the name of your WiFi network
passwd$ = "zillesoftgmbh"  ' Replace passwd with the password to your network
Timeout = 20000            ' Error timeout in milliseconds
echo = 0                   ' Set this to non zero to see all communications

Open "COM1:115200" As #1
SendCmd "AT+RST", "ready"
Print"ESP8266 found. Firmware:"+GetVer$()
SendCmd "AT+CWJAP=" + Chr$(34) + SSID$ + Chr$(34) + Passwd$ + Chr$(34), "OK"
Print "connected to " + SSID$ + ". IP Address " + GetAddr$()
main:
GoTo main
 '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''' ''''''''''''''''''
' This will get the version number of the firmware running on the module
Function GetVer$()
  Local s$, i
  If error Then Exit Sub This should be Function
  ClearBuffer
  Print #1, "AT+GMR"
  For i = 1 To 3
    s$ = GetLine$()
    If error Then Exit For
    If echo Then Print s$
  Next i
  GetVer$ = s$
End Function


 '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''' ''''''''''''''''''
' This will get the IP address of the module
' After connecting to the access point it can take several seconds for the
' command to complete.  This sub will keep trying to get the address and will
' only return when it has it (this signifies that the connection is made).
Function GetAddr$()
  Local s$, i, j
  If error Then Exit Sub  This should be Function
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

 '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''' ''''''''''''''''''
' This is a general purpose sub which will send a command and check
' for the correct response
Sub SendCmd cmd$, response$
  Local InputStr$
  If error Then Exit Sub
 ' ClearBuffer
  Print #1, cmd$
  Do
    InputStr$ = GetLine$()
  Loop Until Instr(InputStr$, response$) > 0 Or error
End Sub

 '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''' ''''''''''''''''''
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