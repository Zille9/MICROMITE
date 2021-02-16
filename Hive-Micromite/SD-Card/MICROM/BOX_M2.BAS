I2CADDR = &h42
I2C OPEN 400, 100
I2C write I2CADDR,0,3,1,2,2 'Switch to mode 2
Pause 1000 : 'Give the Propeller time to switch to MODE 2
I2C write I2CADDR,0,4,1,205,63,1
PropellerCMD 204 :' CLS clear the screen
Randomize 1000
i=0
x=0
xx=511
y=0
yy=383
ps=1
Start:
 xl=x And 255
 xm=0
 If x>255 Then xm=255
 yl=y And 255
 ym=0
 If y>255 Then ym=255
 xxl=xx And 255
 xxm=0
 If xx>255 Then xxm=255
 yyl=yy And 255
 yym=0
 If yy>255 Then yym=255
 i=i+1
 I2C WRITE &h42,0,11,1,207,xm,xl,ym,yl,xxm,xxl,yym,yyl,ps
 Pause 200
 x=x+3
 xx=xx-3
 y=y+3
 yy=yy-3
 nochmal:
   e=Int(63*Rnd(1))*4
   f=Int(63*Rnd(1))*4
   g=Abs(e-f)
   If g<5 Then GoTo nochmal

 If i=125 Then
    I2C write &h42,0,4,1,205,e,f
    Pause 100
    i=0
    x=0
    xx=511
    y=0
    yy=383
    If ps=1 Then
       ps=0
    Else
       ps=1
       propellercmd 204
    EndIf
 EndIf

GoTo Start

Sub PropellerCMD cmd
  I2C WRITE I2CADDR,0,2,1,cmd
  Pause 100
End Sub                                   