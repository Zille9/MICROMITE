SERVER$="23.0.88.120"
PORTX$="80"

Open "Com1:57600, 4096" As #1
FLUSHBUF

Print #1,"AT+CWMODE=3"
Pause 100
GETSTRINGLONG

Print #1,"AT+CIPMUX=0"
Pause 100
GETSTRINGLONG

Print  #1,"AT+CIPSTART="+Chr$(34)+"TCP"+Chr$(34)+","+Chr$(34)+SERVER$+Chr$(34)+","+PORTX$
Print "AT+CIPSTART NOW"
Pause 1000
GETSTRINGLONG

Z$="GET /api/2b4e1c4572808d14/conditions/q/33773.json HTTP/1.1"+Chr$(13)+Chr$(10)+"Host: api.wunderground.com"+Chr$(13)+Chr$(10)
OUTPUTX Z$
Pause 1000
GETSTRINGLONG

Print #1,"AT+CIPCLOSE"
Pause 100
GETSTRINGLONG

End


Sub OUTPUTX (OUT$)
 Print #1,"AT+CIPSEND=0"+Str$(Len(OUT$)+2)
 Pause 200
 Print #1,OUT$
 Print OUT$
 Pause 100
End Sub

'**********GETSTRINGLONG************
Sub GETSTRINGLONG
Pause 200
Print "BYTES IN LOC = ";Loc(#1)
C$=""
Do
C$=Input$(1,#1)
char = Asc(C$)
If char >31 Then Print C$;
If char =13 Then Print " "
Loop While Loc(#1)<>0
End Sub

Sub FLUSHBUF
Do:A$=Input$(1,#1):Loop While Loc(#1) <> 0
End Sub                                  