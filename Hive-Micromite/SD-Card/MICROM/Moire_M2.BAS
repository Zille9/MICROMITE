I2C OPEN 400,100
I2C write &h42,0,3,1,2,2 'switch to mode 2
Pause 100
Propellercmd 204
Pause 1000

start:
PropellerCMD 204
r=Int(Rnd*3)+3
farbe:
c=Int(Rnd*63)*4+1
e=Int(Rnd*63)*4+1
h=Abs(e-c)
If h<4 Then GoTo farbe  'gleiche farben verhindern
color c,e
Pause 100
For t = 1 To 511 Step r
  line 1,1,t,383
  If t<383 Then
     line 1,1,511,t
  EndIf
Next t
Pause 5000
GoTo start

Sub color a,b
 I2C write &h42,0,4,1,205,a,b
End Sub

Sub line a,b,c,d
 xm=0
 xl=a And 255
 If a>255 Then xm=255
 ym=0
 yl=b And 255
 If b>255 Then ym=255
 xxm=0
 xxl=c And 255
 If c>255 Then xxm=255
 yym=0
 yyl=d And 255
 If d>255 Then yym=255
 I2C write &h42,0,11,1,202,xm,xl,ym,yl,xxm,xxl,yym,yyl,1
 Pause 80
End Sub

Sub PROPELLER register,data
  I2C WRITE &h42,0,2,register,data
End Sub

Sub PropellerCMD command
  propeller 1,command
  Pause 20
End Sub        