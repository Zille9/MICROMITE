I2C OPEN 400,200
I2C write &h42,0,3,1,2,6 'switch to mode 6
Pause 1000
start:
ca=Int(Rnd(1)*63*4)
cb=Int(Rnd(1)*63*4)
color ca,0
color2 cb,0
Propellercmd 204
locate 3,2
Print" Darstellung der Funktion Z=X*X-Y*Y"
w=Pi/8
A=0:b=0:d=0
f1=20:f2=5:f3=8
v1=160:v2=100
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

Sub color2 c,d
 I2C write &h42,0,4,1,211,c,d
 Pause 10
End Sub

Sub Locate xa,ya
I2C write &h42,0,4,1,208,xa,ya 'set to 12,5
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

 I2C write &h42,0,6,1,206,xm,xl,b,2
 Pause 8
End Sub


Sub PropellerCMD command
  I2C write &h42,0,2,1,command
  Pause 50
End Sub                                             