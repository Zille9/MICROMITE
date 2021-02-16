Input"Dateiname eingeben: ",Name$
I2C open 10,100
sendFilename Name$
Pause 200
cls
Pause 100
readfile:
PropellerCMD 186 'Read byte from SD into I2C register
I2C WRITE &h42,0,1,&h0
Pause 10
I2C READ &h42,0,1,a$ 'Read register 1 in A

If Asc(a$) = 255 Then End
Print a$;
GoTo readfile

Sub SendFilename file$
 PropellerCMD 230 'Clear all the i2c registers
 For x = 1 To Len(file$)
 I2C write &h42,0,2,x+1,Asc(Mid$(file$,x,1))
 Next x
 PropellerCMD 180  'Tell Propeller to copy filename from registers

 PropellerCMD 181  'Tell Propeller to open the file for reading
End Sub

Sub PropellerCMD cmd
  I2C WRITE &h42,0,2,1,cmd
  Pause 10
End Sub

Sub PropellerVAR var,data
  I2C WRITE &h42,0,2,var,data
End Sub

Sub CLS
  propellerCMD 204
End Sub                                                                                                                       