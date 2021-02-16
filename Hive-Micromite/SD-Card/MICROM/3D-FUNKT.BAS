I2C OPEN 400,200
I2C write &h42,0,3,1,2,2 'switch to mode 2
Pause 1000
start:
ca=Int(Rnd*63+1*4)
color 0,ca
Propellercmd 204
locate 12,5
Print" Darstellung der Funktion Z=X*X-Y*Y"
w=Pi/8
A=0:b=0:d=0
f1=30:f2=12:f3=20
v1=250:v2=200
co=Cos(w):si=Sin(w)
sy=-50:sx=-2
For za=1 To 2
    For yr=300 To -400 Step sy
        For xr=300 To -300 Step sx
            zr=(yr*yr-xr*xr)/100
            x=Int((f1*(a+xr)+f3*(yr+c)*co)/100+v1)
            y=Int((f2*(b+zr)+f3*(yr+c)*si)/100+v2)
            plot x,y
        Next xr
    Next yr
    If za=1 Then sy=-1:sx=-50
Next za
Pause 5000
GoTo start

Sub color a,b
 I2C write &h42,0,4,1,205,a,b
 Pause 10
End Sub

Sub Locate xa,ya
I2C write &h42,0,4,1,208,12,5 'set to 12,5
Pause 50
End Sub

Sub Plot a,b

 If a>255 Then
    xl=a And 255
    xm=255
 Else
    xm=0
    xl=a
 EndIf
 If b>255 Then
    yl=b And 255
    ym=255
 Else
    ym=0
    yl=b
 EndIf

 I2C write &h42,0,7,1,206,xm,xl,ym,yl,1
 Pause 10
End Sub


Sub PropellerCMD command
  I2C write &h42,0,2,1,command
  Pause 50
End Sub                                                             