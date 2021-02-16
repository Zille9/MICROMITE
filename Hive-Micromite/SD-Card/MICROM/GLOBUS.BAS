10 I2C open 400,100
11 I2C write &h42,0,3,1,2,2 'switch to mode 2
12 Pause 100
13 Restore
14 'propellercmd 204
15 GoTo 210
20 Y=R*CP: X=Y*CL: Y=Y*SL: Z=R*SP
30 XX=(AX*X)+(AY*Y)+(AZ*Z): YY=(BX*X)+(BY*Y)+(BZ*Z)
40 ZZ=(CX*X)+(CY*Y)+(CZ*Z)
42 If YY>0 Then
45    F2=0: F1=0
47    Return
48 EndIf
50 X2=X0+XX+H: Y2=Y0-ZZ+H: F2=1
60 If F1=0 Then
62    X1=X2: Y1=Y2: F1=1
63    Return
64 EndIf
65 '!--------- Gerade ---------
70 If X2=X1 Then
71    U=1E38: GoTo 110
75 EndIf
80 U=(Y2-Y1)/(X2-X1)
85 If Abs(U)>1 Then GoTo 110
90 Y=Y1+H: T=Sgn(X2-X1)
95 If T<0 Then U=-U
100 For SX=X1 To X2 Step T
102    PSET SX,Int(Y): Y=Y+U
105 Next SX: GoTo 130
110 X=X1+H: U=1/U: T=Sgn(Y2-Y1)
102 If T<0 Then U=-U
120 For SY=Y1 To Y2 Step T
122    PSET Int(X),SY: X=X+U':Print x,y;
125 Next SY
130 F1=F2: X1=X2: Y1=Y2: Return
135 '!-------- Kreis ----------
140 Y2=0: D=R/Sqr(2)+h: X2=R*R: X=R: R2=X2+D
150  For SY=0 To Int(d)
152   If Y2+X2>R2 Then
155      X2=X2-X-X+1: X=X-1
157   EndIf
160   PSET X0+X,Y0+SY: PSET X0+SY,Y0+X
170   PSET X0-SY,Y0+X: PSET X0-X,Y0+SY
180   PSET X0-X,Y0-SY: PSET X0-SY,Y0-X
190   PSET X0+SY,Y0-X: PSET X0+X,Y0-SY: Y2=Y2+SY+SY+1
200  Next SY: Return
205 '!--------- Main ----------
210 Print " R.Zielinski"
220 Print "Alle Winkel in Grad": BM=Pi/180
230 Input "Geografische Laenge"; CW: C=-(CW+90)*BM
240 Input "Geografische Breite"; AW: A=-AW*BM
250 Input "Neigung  der  Achse"; BW: B=-BW*BM
260 Input "Abstand  der Kreise"; QW: Q=QW*BM
270 propellercmd 204: O=4: X0=256: Y0=70: R=170: H=.5: GoSub 140
280 S1=Sin(A): S2=Sin(B): S3=Sin(C)
290 C1=Cos(A): C2=Cos(B): C3=Cos(C)
300 AX=C2*C3:  AY=-C2*S3: AZ=S2
310 BX=C1*S3+S1*S2*C3:  BY=C1*C3-S1*S2*S3
320 BZ=-S1*C2:  CX=S1*S3-C1*S2*C3
330 CY=S1*C3+C1*S2*S3:  CZ=C1*C2: F1=0: C0=1
335 '!--------- Karte ----------
340 For J=1 To 292
341 Read A,B
342 If A=.1 Then
343    D0=B:A=A0:B=B0:C0=0
344 EndIf
350 If C0=1 Then
351    A0=A: B0=B: C0=-1
355 EndIf
360 L=A*BM: P=-B*BM: CL=Cos(L): SL=Sin(L): CP=Cos(P): SP=Sin(P): GoSub 20
370 If C0=0 Then
371    A=D0
372    Read B
373    C0=1: F1=0
375    GoTo 350
376 EndIf
380 Next j
385 '!-------- Laengenkreise -----
390 For L=0 To 100*(Pi-q) Step (100*q)
395     F1=0: CL=Cos(L/100): SL=Sin(L/100)
400 For P=0 To (2*Pi+bm)*100 Step 2.5*bm*100
405     CP=Cos(P/100): SP=Sin(P/100): GoSub 20
410 Next p,l
415 '!-------- Breitenkreise -----
420 For P=((-Pi/2)+Q)*100 To ((Pi/2)-q)*100 Step q*100
422    F1=0:CP=Cos(P/100): SP=Sin(P/100)
430    For L=0 To (2*Pi+bm)*100 Step 2.5*bm*100
432        CL=Cos(L/100): SL=Sin(L/100):GoSub 20
440 Next L:Next P
450 locate 2,45:Print" Nochmal? J/N"
452 command$=Inkey$
453 If command$="j" Then GoTo 13
455 If command$="n" Then End
470 GoTo 452
485 '!------------ Daten ---------
490 Data 355,50,1,51,2,52,358,56,359,57,357,58,353,58,355,55,356,55,0.1,28,72
500 Data 15,68,9,63,5,62,6,58,8,58,10,59,12,56,11,56,11,57,9,56,9,54,6,53,3,51
510 Data 356,48,358,45,358,43,352,43,352,36,355,35,358,36,4,44,6,44,9,45,16
520 Data 39,16,38,13,38,15,37,18,39,17,40,18,41,19,40,13,44,14,45,19,42,20,40
530 Data 23,36,25,38,24,40,26,41,27,36,37,36,36,32,21,33,21,32,11,33,12,34
540 Data 357,33,355,34,342,20,342,11,351,5,10,5,8,0,13,-8,12,-18,18,-24
550 Data 28,-24,41,-15,40,-5,52,12,43,12,38,20,34,28,43,12,58,18,60,22,51,23
560 Data 48,30,68,23,77,8,80,10,80,7,82,8,80,10,80,15,90,22,95,16,97,17,99,8
570 Data 104,2,100,13,106,8,110,13,106,20,109,21,109,19,121,27,121,40
580 Data 124,39,126,33,130,35,131,41,140,48,140,57,160,61,155,51
590 Data 163,55,190,67,130,72,95,82,95,76,69,69,35,65,33,67,38,67
600 Data 42,68,0.1,12,54,13,55,15,54,21,55,23,59,30,60,22,61,26,66,24,66
610 Data 16,55,0.1,23,35,26,35,.1,32,35,34,35,0.1,44,-25,47,-25,50,-12,44,-18
620 Data 0.1,165,-47,172,-47,178,-38,172,-35,172,-40,.1,128,0,141,-9,153,-12
630 Data 145,-5,0.1,118,9,125,5,126,11,122,19,0.1,90,8,107,-8,126,-10,106,-5
640 Data 0.1,109,2,110,-3,117,-4,119,8,0.1,118,-5,123,-5,125,2,120,2,0.1,130,30
650 Data 140,36,145,45,142,45,142,55,138,38,130,33,0.1,49,38,55,37,51,45,54,48
660 Data 48,47,0.1,28,42,42,42,36,44,39,47,34,43,36,44,30,46,31,46,0.1,350,51
670 Data 353,53,354,55,353,56,350,53,.1,51,-67,102,-66,140,-67,172,-72
680 Data 160,-81,210,-85,200,-76,225,-75,300,-63,298,-78,354,-71
690 Data 0.1,315,60,338,70,345,82,330,84,295,81,290,76,300,75,312,62
700 Data 0.1,346,63,346,68,336,67,337,63,0.1,18,76,32,80,10,79,0.1,50,72,55,71
710 Data 69,78,0.1,276,22,278,23,295,20,280,18,278,22,0.1,288,13,283,9
720 Data 279,9,276,11,276,15,272,17,273,22,270,21,269,19,263,20,263,28
730 Data 277,30,279,24,278,31,307,48,296,60,282,63,280,51,265,60,280,70
740 Data 286,68,282,63,296,62,298,66,280,74,300,83,228,70,200,70,193,67
750 Data 195,62,202,57,190,53,215,60,235,48,236,35,250,22,245,32,255,18,273,12
760 Data 279,8,283,8,278,-5,290,-19,283,-52,292,-55,296,-54,292,-51,294,-47
770 Data 293,-45,315,-23,320,-23,322,-12,325,-6,310,0,308,5,298,11
780 Data 0.1,114,-22,132,-12,137,-12,140,-16,142,-11,152,-26,148,-43,135,-35
790 Data 115,-35,0.1,9,43,9,42,8,41,8,39,10,40,0.1,-2,60,-2,62,0.1,-7,63,-7,65

Sub color cla,clb
 I2C write &h42,0,4,1,205,cla,clb
 Pause 50
End Sub

Sub locate lca,lcb
    I2C write &h42,0,4,1,208,lca,lcb
    Pause 10
End Sub

Sub Pset psa,psb
 clp=255-psb
 xm=0
 If psa>255 Then
    xl=psa And 255
    xm=255
 Else
    xl=psa
 EndIf
 ym=0
 If clp>255 Then
    yl=clp And 255
    ym=255
 Else
    yl=clp
 EndIf
 I2C write &h42,0,7,1,206,xm,xl,ym,yl,1
 Pause 10
End Sub

Sub PropellerCMD command
  I2C write &h42,0,2,1,command
  Pause 20
End Sub                                                                                                                  