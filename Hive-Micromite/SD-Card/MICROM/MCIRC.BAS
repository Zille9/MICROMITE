' mcIRC V2.0 - By Jeff Ledger
' http://www.propellerpowered.com
' Uses the ESP8266 module.
' This program assumes you have already programmed the wireless
' ESP8266 unit for your network and have it connected.

'IRCSERVER$="irc.newnet.net"
IRCSERVER$="eu.german-elite.net"'"130.240.22.202" 'newnet has a dead ip in their round-robin bank
IRCPORT$="6667"
IRCNICK$="Zille9"                       'Irc Nick
IRCNAME$="Rufus Firefox"                'Irc Realname
CHANNEL$="#hive"'"#propellerpowered"    'Irc Channel

COLOR 31,40
CLS
Print Chr$(27)+"[?6h"; 'Turn on region mode
LOCATE 1,1
line(4)
color 35,40
Print " MICROMITE COMPANION IRC CLIENT ";
color 31,40
line(44)
locate 24,1
line(80)
locate 28,1
line(80)
color 36,40
locate 27,1
Print ":]";
Print Chr$(27)+"[3;23r"; 'set scroll region
locate 23,1
Print "                ___ ____   ____ "
Print " _ __ ___   ___|_ _|  _ \ / ___| For Micromite Companion"
Print "| '_ ` _ \ / __|| || |_) | |     and the ESP8266 Module"
Print "| | | | | | (__ | ||  _ <| |___ "
Print "|_| |_| |_|\___|___|_| \_\\____| By Jeff Ledger"
Print "                                "
color 32,40
Open "Com1:57600" As #1
Randomize Timer
Print "*** PLEASE WAIT WHILE WE LOG INTO "+CHANNEL$+" ***"
color 37,40
Print " "
Print "Connecting...."
Print " "
Print #1,"AT+CIPSTART="+Chr$(34)+"TCP"+Chr$(34);
Print #1,","+Chr$(34)+IRCSERVER$+Chr$(34)+","+IRCPORT$
pong=0
login=0
textx=3

IRC:
a$=""
b$=""
a$=Inkey$

If Asc(a$) > 31 And textx < 75 Then
 Print Chr$(27)+"[25;27r"; 'set scroll region
 locate 27,textx
 textx=textx+1
 Print a$;
 d$=d$+a$
EndIf

If Asc(a$) = 8 And textx > 3 Then
 Print Chr$(27)+"[25;27r";
 locate 27,textx
 Print Chr$(8)+Chr$(32)+Chr$(8);
 textx=textx-1
 'locate 27,textx
 d$=Left$(d$,Len(d$)-1)
 a$=""
EndIf

If Asc(a$)=13 Then
 chanout d$
 Print Chr$(27)+"[25;27r";
 locate 27,1
 Print "  ";
 locate 27,textx
 Print " "
 color 36,40
 locate 27,1
 Print ":]";
 color 37,40
 d$=""
 textx=3
EndIf

If a$=Chr$(27) Then
 a$=""
 'chanout "mcIRC Connection Closed - http://hive-project.de"
 output "quit"
 normal
 Print " "
 Print " "
 Print " "
 Print "mcIRC Closed..."
 Pause 1000
 Print #1,"AT+CIPCLOSE"
 End
EndIf

'If a$ <> "" Then Print #1,a$;

If Loc(#1) >=1 Then b$=Input$(1,#1)
char = Asc(b$)
If char >31 And Len(c$) < 254 Then c$=c$+b$
If char =13 Then
  If Right$(c$,1)="~" Then output "nick "+IRCNICK$
  If Mid$(c$,9,4)="PING" Then
     output "PONG :"+Mid$(c$,15,Len(c$))
     pong=1
     c$=""
  EndIf
  If pong=1 And login=0 Then
     Pause 1000
     output "user "+IRCNICK$+" localhost localhost:"+IRCNAME$
     Pause 1000
     output "join "+CHANNEL$
     login=1
     Pause 1000
     color 32,40
     Print " "
     Print "*** LOGGED INTO CHANNEL: "+CHANNEL$+" ***"
     Print " "
     color 31,40 : Print "("; : color 37,40 : Print "-"; : color 31,40
     Print ")"; : color 37,40 : Print " to logout of the IRC connection."
     Print " "
     Print "Channel Commands: "
     Print " "
     color 33,40
     Print "!time = Display current time on the Micromite"
     Print "!date = Display current date on the Micromite"
     Print "!random = Display a random number from 1-100"
     Print "!magic8ball = Consult the magic8ball."
     Print " "
     color 37,40
  EndIf
  If Right$(c$,5)="!time" Then
     chanout Time$
   EndIf
  If Right$(c$,5)="!date" Then
     chanout Date$
  EndIf
  If Right$(c$,7)="!random" Then
     chanout "Random Number is "+Str$(Int(100*Rnd))
  EndIf
  If Right$(c$,11)="!magic8ball" Then
    aa=Int(6*Rnd)
    If aa=0 Then chanout "Outlook uncertain"
    If aa=1 Then chanout "It is certain"
    If aa=2 Then chanout "Without a Doubt"
    If aa=3 Then chanout "As I see it, yes"
    If aa=4 Then chanout "Don't count on it"
    If aa=5 Then chanout "My reply is no"
    If aa=6 Then chanout "Concentrate & Ask again"
 EndIf
 If Right$(c$,2)="OK" Then c$=""
 If Right$(c$,4)="busy" Then c$=""
 If Left$(c$,4)="+IPD" And Mid$(c$,9,2)="::" And login=1 Then textparse(11)
 If Left$(c$,4)="+IPD" And Mid$(c$,8,2)="::" And login=1 Then textparse(10)
 If Left$(c$,4)="+IPD" Then
    Print Chr$(27)+"[3;23r"; 'set scroll region
    locate 23,1
    For x = 10 To Len(c$)
       Print Mid$(c$,x,1);
    Next x
    Print " "
 EndIf
c$=""
EndIf
GoTo IRC

Sub Textparse xx
 Print Chr$(27)+"[3;23r"; 'set scroll region
 locate 23,1
 color 31,40
'Parse the speaker's nick
 Print "[";Left$(Time$,5);"][";
 parsename:
 color 33,40
 If xx > 254 Then  xx=11
 aa$=Mid$(c$,xx,1)
 If aa$ <> "!" Then
   xx=xx+1
   Print aa$;
 EndIf
 If aa$="!" Then GoTo parsedone
 GoTo parsename
parsedone:
color 31,40
Print "]";
'Parse the chat text
 colon=0
 color 37,40
 For x=1 To Len(c$)
 aa$=Mid$(c$,x,1)
 If aa$=":" And colon=0 Then
    colon=1
    aa$=""
 EndIf
 If aa$=":" And colon=1 Then
    colon=2
    aa$=""
 EndIf
 If aa$=":" And colon=2 Then
   colon=3
   aa$=""
 EndIf
 If colon=3 And aa$<>"" Then
    Print aa$;
 EndIf
 Next x
Print" "
colon=0
c$="" 'remark this to see raw irc data
End Sub

Sub output out$
 Print #1,"AT+CIPSEND=0"+Str$(Len(out$)+2)
 Pause 200
 Print #1,out$
 Print #1,Chr$(13)+Chr$(10);
 Pause 100
End Sub

Sub chanout out$
Print Chr$(27)+"[3;23r"; 'set scroll region
 locate 23,1
 text$="privmsg "+CHANNEL$+" : "+out$
 Print #1,"AT+CIPSEND=0"+Str$(Len(text$)+2)
 Pause 200
 Print #1,text$
 Print #1,Chr$(13)+Chr$(10);
 color 31,40
 Print "[";Left$(Time$,5);"][";
 color 35,40
 Print IRCNICK$;
 color 31,40
 Print "]";
 color 37,40
 Print out$
 Pause 100
End Sub

Sub line linel
 For x = 1 To linel
 Print Chr$(146);
 Next x
End Sub

Sub CLS
 Print Chr$(27)+"[f";:Print Chr$(27)+"[2J";
End Sub

Sub LOCATE x,y
 Print Chr$(27)+"["+Str$(x)+";"+Str$(y)+"f";
End Sub

Sub COLOR f,b
 Print Chr$(27)+"[0;"+Str$(f)+";"+Str$(b)+";1m";
End Sub

Sub NORMAL
 Print Chr$(27)+"[?6l";                                                                                                                         