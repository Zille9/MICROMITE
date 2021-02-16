' Configuration constants
TZ = 0               'From GMT (+ or -)
PowerSave=0          '1 moudule Off after update 0 Allways On
                     '1 Will cause a small delay during update
UpDate=1'60            'Update frequency in Minutes
DST=1                '1 Use DST 0 Disable
DMS=9                'Month DST Time Starts
DHS=2                'DST Start Hour
DME=4                'Month DST Time Starts
DHE=3                'DST Stop Hour

SSID$ = "Diablo"                  'name of wireless access point To connect To
PASS$ = "zillesoftgmbh"                    'WiFi Password
Port$ = ",123"                             'NTP UDP port
NTP$="217.13.75.19" 'Braunschweig          'NTP Server you want to use

Dim Months(12)       'Array for Months
For I=1 To 12
 Read Months(I)
Next I

Dim Days$(7)
For I=0 To 6
 Read Days$(I)
Next I

Dim Mnths$(12)       'Array for Months Names
For I=1 To 12
 Read Mnths$(I)
Next

LeapMnth=2505600     'Seconds in Leap Year February
Lcount=48
Dim Line$(48)        'UDP data array

Reset

Open "COM1:57600, 1024" As #1  'Module must be set to same rate
Print #1,"AT+RST"
Pause 1000
Print #1, "AT+CWMODE=1"
Pause 1000

Print #1, "AT+CIPMUX=0"       ' Set Single connection
Pause 2000

ConnectToWiFi:
Print  #1,"AT+CWJAP=+Chr$(34)+SSID$+Chr$(34)+","+Chr$(34)+PASS$+Chr$(34)"
Print"Connecting to ";SSID$
Pause 5000 'give it time to connect

Flushbuf

Print #1, "AT+CIFSR"
 Pause 1500
Line Input #1,IP$
Line Input #1,IP$
Line Input #1,IP$
Print "Connected IP ";IP$

Line$(1)=Chr$(27)             '1st byte Minimum requirement for valid respone
Line$(2)=""                   'Incase we end up back here
For I = 1 To 47               'Load next 47 bytes with null
 Line$(2)=Line$(2)+Chr$(0)
Next I

GetNTPTime:
flushbuf
Print #1,"AT+CIPSTART="+Chr$(34)+"UDP"+Chr$(34)+","+Chr$(34)+NTP$+Chr$(34)+Port$
Delay
Print #1,"AT+CIPSEND=48" '+Str$(Len(&hE3))
Delay
Print #1, Line$(1)+Line$(2) '+Line$(3)+Line$(4);
Delay
Print #1, "AT+CIPCLOSE"
Pause 1500

For I =1 To 10
 Line Input #1,IP$        'Unrelated info
 Print IP$
Next I

IP$ = Input$(1, #1)
Print ip$
IP$ = Input$(8, #1)       ' Sanity Check
If Ip$<> "+IPD,48:" Then
 Print "Connection Error"
Print"Connecting Error, retry!"
Pause 3000
GoTo ConnectToWiFi
EndIf

IP$ = Input$(48, #1)

flushbuf

lw1$=Str$(Asc(Mid$(ip$,41,1)))  'Extract 1st Byte
lw2$=Str$(Asc(Mid$(ip$,42,1)))  'Extract 2nd Byte
lw3$=Str$(Asc(Mid$(ip$,43,1)))  'Extract 3rd Byte
lw4$=Str$(Asc(Mid$(ip$,44,1)))  'Extract 4th Byte
lb1% = Val(lw1$) << 8
lb1% = (lb1% Or Val(lw2$)) << 16 'MSB 32 Bit Number
lb2% = Val(lw3$) << 8
lb2% = lb2% Or Val(lw4$)        'LSB 32 Bit Number

LB% = LB1% + LB2%
LB% = LB% - 2208988800          ' - 70 Years start @ 1/1/1970 Epoch time

Jan2014 = LB% - 1388534400      'Start at Jan 1/1/2014
TimeZone = (TZ*60*60)           'Set TimeZone
Jan2014=Jan2014+TimeZone        'Adjust for Timezone
Year=2014                       'Set Year to 2014

GetYear:
 LEAP = Year Mod 4              '0 if leap year
   If LEAP = 0 Then
    SecondsInYear = 31622400    '366*60*60**24
   Else
    SecondsInYear = 31536000    '365*60*60*24
   EndIf
  If Jan2014 > SecondsInYear Then
   Jan2014 = Jan2014 - SecondsInyear
   Year = Year + 1
    GoTo GetYear
  EndIf

Month = 1 ' Start with Month = 1

GetMonth:
SecondsInMonth = Months(Month)
 If Leap = 0 Then
   If Month = 2 Then
   SecondsInMonth=LeapMnth
 EndIf
   EndIf
 If Jan2014 >= SecondsInMonth Then
   Jan2014 = Jan2014 - SecondsInMonth
   Month = Month+1
   GoTo GetMonth
 EndIf

FindDays:
Day = Int(Jan2014/86400)
Jan2014 = Jan2014 Mod 86400
Hour = Int(Jan2014/3600)
Jan2014 = Jan2014 Mod 3600
Min = Int(Jan2014/60)
Jan2014 = Jan2014 Mod 60
Sec = Jan2014+2           '+2 Zeitkorrektur bis zur Anzeige
Day = Day + 1

If DST = 1 Then
 GoSub DsTime
 If CurrDT < DsStop Or CurrDT > DsStart Then
 Hour = Hour + 1
EndIf
EndIf

If Hour=24 Then hour=0

Date$=Str$(Day)+"/"+Str$(Month)+"/"+Str$(Year)
Time$=Str$(Hour)+":"+Str$(Min)+":"+Str$(Sec)

Print Time$
Print Date$


Timer=0
 Do While Timer < (UpDate*60*1000)           'Update frequency
 DayOfWeek
 LongDate$=Days$(Dow)+" "+Left$(Date$,2)+" "+Mnths$(Val(Mid$(Date$,4,2)))

LengthCheck:
If Len(LongDate$) < 16 Then
   LongDate$=LongDate$+" "
   GoTo LengthCheck
EndIf

  Print LongDate$
  Print "NTP      "+Time$
  Pause 1000
Loop
 Print"Updating..    "

GoTo GetNTPTime

End

DsTime:
'DSTime is used to find the stop and start dates for DST
'Reference http://delphiforfun.org/programs/math_topics/dstcalc.htm

 Local YT
 YT=Int((5*Year)/4)
 DsdStop=7-((4+YT) Mod 7)         'NZ 1st Sunday in April
 DsdStart=31-((YT-1) Mod 7)       'NZ Last Sunday in September

'You will need modify the above lines to suit your DST
'DsdStart=14-((1+Year*5/4) mod 7) 'USA 2nd Sunday in March
'DsdStop=7-((1+YT) mod 7)         'USA 1st Sunday November
'DsdStart=31-((4+YT) mod 7)       'EU Last sunday in March
'DsdStop=31-((1+YT) mod 7)        'EU Last Sunday October

DsStart=(DMS*10000)+(DsdStart*100)+DHS
DsStop=(DME*10000)+(DsdStop*100)+DHE
CurrDT=(Val(Mid$(Date$,4,2))*10000)+(Day*100)+Hours

Return

Sub DayOfWeek                          'TZ's Method
 A = Int((14-Val(Mid$(Date$,4,2)))/12)
 M = Val(Mid$(Date$,4,2)) + 12*a - 2
 Y = Val(Mid$(Date$,7,4)) -a
 D = Val(Mid$(Date$,1,2))
 Dow=(D+Y+Int(Y/4)-Int(y/100)+Int(Y/400)+Int(31*M/12)) Mod 7
End Sub

Sub Delay
 Pause 500
End Sub

Sub FLUSHBUF
 Do:Z$=Input$(1,#1):Loop While Loc(#1) <> 0
End Sub

Sub Reset
 Pin(14)=0  ' Reset Module Disabled
  Pause 500
 Pin(14)=1
End Sub

Data 2678400,2419200,2678400,2592000,2678400,2592000,2678400
Data 2678400,2592000,2678400,2592000,2678400
Data "Sunday","Monday","Tuesday","Wednesday","Thursday"
Data "Friday","Saturday"
Data "Jan","Feb","Mar","Apr","May","June"
Data "July","Aug","Sep","Oct","Nov","Dec"                        