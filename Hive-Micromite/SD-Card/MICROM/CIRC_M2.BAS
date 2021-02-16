I2C OPEN 400,100
I2C write &h42,0,3,1,2,2 'switch to mode 2
Pause 100
Propellercmd 204
Pause 1000

start:
'PropellerCMD 204
r=Int(Rnd*90)+1

farbe:
c=Int(Rnd*63)*4+1
e=Int(Rnd*63)*4+1
h=Abs(e-c)
If h<4 Then GoTo farbe  'gleiche farben verhindern
color c,e
Pause 100
propellercmd 204
'circ 250,192
For i=0 To 360 Step 15
  w=2*Pi/360*i
  circ 250+90*Cos(w),192+90*Sin(w)
  Pause 400
Next i
line 250,192

Pause 5000
GoTo start

Sub circ x,y
 xm=0
 xl=x And 255
 If x>255 Then xm=255
 ym=0
 yl=y And 255
 If y>255 Then ym=255

 I2C write &h42,0,11,1,203,xl,xm,yl,ym,90,0,90,0,1
 'For t=1 To 200*Pi Step 1
 'plot x+90*Cos(t/100),y+90*Sin(t/100)
 'Next t
 Pause 50
End Sub

Sub line x,y
 For t=1 To 200*Pi Step 200*Pi/360*15
 lines x,y,x+135*Cos(t/100),y+135*Sin(t/100)
 Next t
End Sub

Sub lines x,y,xx,yy
 xm=0
 xl=x And 255
 If x>255 Then xm=255
 ym=0
 yl=y And 255
 If y>255 Then ym=255
 xxm=0
 xxl=xx And 255
 If xx>255 Then xxm=255
 yym=0
 yyl=yy And 255
 If yy>255 Then yym=255
 I2C write &h42,0,11,1,202,xm,xl,ym,yl,xxm,xxl,yym,yyl,1
 Pause 20
End Sub

Sub color a,b
 I2C write &h42,0,4,1,205,a,b
End Sub

Sub Plot a,b
 xm=0
 xl=a And 255
 If a>255 Then xm=255
 ym=0
 yl=b And 255
 If b>255 Then ym=255

 I2C write &h42,0,7,1,206,xm,xl,ym,yl,1
 Pause 10
End Sub

Sub PROPELLER register,data
  I2C WRITE &h42,0,2,register,data
End Sub

Sub PropellerCMD command
  propeller 1,command
  Pause 20
End Sub                                           