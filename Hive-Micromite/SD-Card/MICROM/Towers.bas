  ''''''''''''''''''''''''''''''''''''''
  '''''''''''TOWERS of HANOI''''''''''''
  ''''''''''''''''''''''''''''''''''''''
  ''''''''''''By H W Holmes'''''''''''''
  ''''''''''''''''''''''''''''''''''''''
  ''''''''''''July 31, 2014'''''''''''''
  ''''''''''''''''''''''''''''''''''''''

  'This program plays the game of Towers of Hanoi for you.
  'It is a programing exercise in recursion, that is,
  'where a subroutine, in this case "TOWER", calls itself.

  'It plays on a MicroMite using a VT100 terminal .eg Tera Term.
  'It does NOT play in the chat window of MMEdit prior to V3.4.18

INFO:
  '''''''''''''''''''''''
  '''Display Constants'''
  '''''''''''''''''''''''
  Delay = 500 ' Change for speed of play
  TopRow = 8  ' CHANGE THIS TO MOVE Game UP OR DOWN THE SCREEN!

  ''''''''''''''''
  ''Tower Pieces''
  ''''''''''''''''
  Dim TP$(9)
  TP$(0) = "       M       "  ' Empty Peg
  TP$(1) = "      1M1      "  ' Level 1
  TP$(2) = "     22M22     "
  TP$(3) = "    333M333    "
  TP$(4) = "   4444M4444   "
  TP$(5) = "  55555M55555  "
  TP$(6) = " 666666M666666 "
  TP$(7) = "7777777M7777777"  ' level 7
  TP$(8) = "TTTTTTTTTTTTTTT"  ' Base
  TP$(9) = "               "  ' ERASE disk

  Dim PL(3)  'Pin Level

HMD:  'How many disks?

  ClearScreen
  HOME
  ' c 1.1

  Print "This program plays the game of Towers of Hanoi for you."
  Print "Object: To Move Disks from 1 Pin To Another, 1 pin at a time,"
  Print "        never puting a larger Disk on a smaller one."

  '''''''''''''''
  ''''Display''''
  '''''''''''''''
  D=0:S=0:E=0

  ScreenBuild
  Print

DK:
  Print "How many Disks (1-7) " ; : GetDig D : Print D
  If D<1 Or D>7 Then Print "Disk Count Out of Range! -> "; : GoTo DK
SP:
  Print "Starting on Pin (1-3)"; : GetDig S : Print S
  If S<1 Or S>3 Then Print "Pin # Out of Range! -> "; : GoTo SP
EP:
  cnt = 0
  Print "Move to Pin (";
  If S<>1 Then Print "1";: cnt = 1: Print" OR "; ' 1 was not chosen to start
  If S<>2 Then   ' 2 was not chosen to start
    Print "2"; : cnt = cnt + 1
    If cnt = 1 Then Print " OR ";: Print "3"; 'must be the other not chosen
  Else
    Print "3";  'must be the other not chosen
  EndIf
  Print ") "; : GetDig E : Print  E' get end destination pin
  If E<1 Or E>3 Then Print "Pin # Out of Range! -> "; : GoTo EP
  If E=S Then Print "Pin # Same as Start Pin! -> "; : GoTo EP

  Print
SUMARY:
  Print "Move" D " Disks From Pin" S " TO Pin" E "  " ;
  Print "Correct? (Y,N)  ";:  GetKey A$  ' Did you type your choices correctly?
  Print A$; : If (A$ = "N") Or (A$ = "n") Then GoTo HMD
  If (A$ <> "Y") And (A$ <> "y") Then
  Print : Print "Press Y or N - "; : GoTo Sumary : EndIf

SETUP:  'c y,x notes below indicate cursor position for calulating page layout
  ClearScreen
  HOME
  Print "          T O W E R S  O F  H A N O I"
  ' c 2.1
  Print "Object: To Move" D " Disks from Pin" S " To Pin" E
  ' c 3,1
  Print "1 pin at a time, never puting a larger Disk on "
  Print "a smaller one."
  Print
  ' c 6,1           1         2         3
  '        123456789012345678901234567890123
  Print "Moving Disk _ From Pin _ To Pin _."
  ' c 6,1
  SHOW_MOVE

Sub SHOW_MOVE d,s,e   'fills in the above blanks for disk and pins
  yx 6,13: dS d: cr 10: dS s: cr 8: dS e
  Pause Delay
End Sub

  ' c 5,33

PLAY:
  ScreenBuild

Sub ScreenBuild
  yx (toprow + 2,1)
  For I = 0 To 7            ' 8 peg levels - 0-7
    Level = MAX(0,(I+D-7))  ' negative disk levels use empty peg (0)
    For J = 1 To 3          ' 3 pegs
      If Not (J = S) Then
        Print TP$(0);       ' empty peg
      Else
        Print TP$(Level);   ' Empty peg if Level = 0
      EndIf
    Next J
    Print
  Next I
  For iI = 1 To 3: Print TP$(8);: Next: Print ' 3 wide base
  Print "     PIN 1          PIN 2          PIN 3"  ' ID labeling
End Sub


  ''''''''''''''''''''''''''
  '''''''''THE GAME'''''''''
  ''''''''''''''''''''''''''
  'set pin current relative levels of top disk down from top of pin
INIT:
  PL(s) = 7-d
  PL(e) = 7
  PL(6-e-s) = 7

  TOWER d,s,e

  yx TopRow+12, 1
FINI:
  Print "Play Again (Y,N)   "; : GetKey A$ : Print A$
  If (A$ = "N") Or (A$ = "n") Then
    Print " I Hope you liked chalenging me to play the game!": End : EndIf
  If (A$ <> "Y") And (A$ <> "y") Then
  Print "Press Y or N - "; : GoTo FINI : EndIf
  Pause 1000: GoTo HMD
End


Sub TOWER d,s,e
  Local Nd,Ns,Ne    'Next values for d,s,e
  If d <> 1 Then
    Nd = d-1: Ns = s: Ne = 6-s-e
    TOWER Nd,Ns,Ne
  EndIf
  MOVE d,s,e
  If d <> 1 Then
    Ns = Ne: Ne = e
    TOWER Nd,Ns,Ne
  EndIf
End Sub


Sub MOVE d,s,e
  SHOW_MOVE d,s,e  '  Update the header line describing the current move

  'Empty Current Pin Level & Move Up
  yx (toprow + 3 + PL(s),15*(S-1)+1): Print TP$(0); 'clear old pin position
  PL(s) = PL(s)+1     '  Adjuist Pin Level
  yx (toprow,15*(S-1)+1): Print TP$(d);   'place pin above to move sideways
  Pause Delay

  'Clear Position & move Across
  yx (toprow,15*(s-1)+1): Print TP$(9); 'erase current disk position

  '  Do long move in two steps; comment out the whole if structure to speed up
  If Abs(s-e)=2 Then  ' is this a long move?
    dir = Sgn(e-s)    'which way?
    'place disk in intermediate position
    yx (toprow,15*(e-dir-1)+1): Print TP$(d);
    Pause Delay ' let disk settle
    'erase disk from intermediate position
    yx (toprow,15*(s+dir-1)+1): Print TP$(9);
  EndIf

  ' Place Disk above destination pin
  yx (toprow,15*(e-1)+1): Print TP$(d);
  Pause Delay

  'Clear position and Place Disk
  yx (toprow,15*(e-1)+1): Print TP$(9); 'Clear disk from top
  yx (toprow + 2 + PL(e),15*(e-1)+1): Print TP$(d);  'Place disk at end
  PL(e) = PL(e)-1  ' Adjuist Pin Level  compensate pin level for new disk
  Pause Delay

End Sub

  '''''''''''''''''''''''''''''''''''''
  ''''''Cursor Control Subrouines''''''
  '''''''''''''''''''''''''''''''''''''

Sub CU n ' UP
  Print Chr$(27)+"["+Str$(n)+"A";
End Sub

Sub CD n  ' Down
  Print Chr$(27)+"["+Str$(n)+"B";
End Sub

Sub CR n  ' Right (This is the only one I used once I wrote Sub YX)
  Print Chr$(27)+"["+Str$(n)+"C";
End Sub

Sub CL n  ' Left
  Print Chr$(27)+"["+Str$(n)+"D";
End Sub


Sub YX n, m       ' Move cursor to Y,X - (VT100 is 1,1 based
  Local s$
  Print Chr$(27)+"["+Str$(n)+";"+Str$(m)+"H";
End Sub

Sub HOME          ' Equivalent to YX 1,1
  Print Chr$(27)+"[1;1H";
End Sub

Sub ClearScreen
  Print Chr$(27)+"[2J";
End Sub


  ''''''''''''''''''''''
  '''SIMPLE FUNCTIONS'''
  ''''''''''''''''''''''


Sub dS S  'Display Numeric String and leave cursor where it stops.
  Print Str$(S); 'Print Char Data  -  don't use automatic space padding
End Sub

Sub GetDig D
GD:
  Da$ = Inkey$
  If (da$<"0") Or (da$>"9")  Then GoTo GD
  D = Asc(da$)-48
End Sub

Sub GetKey A$
GK:
  A$ = Inkey$
  If (A$ >= " ") And (A$ <= "z") Then Exit Sub
  'If (a$ = "Y") Or (a$ = "y") Or (a$ = "N") Or (a$ = "n") Then Exit Sub
  GoTo GK
End Sub

Function MAX(a,b)       'self explained
  If a>= b Then: MAX=a:Else: MAX=b: EndIf
End Function













































































                                                       