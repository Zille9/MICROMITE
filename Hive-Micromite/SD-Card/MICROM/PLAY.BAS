I2C open 10,100
sendFilename "plastic.dmp"
cls
PropellerCMD 240 'Play Dmp-File
End

Sub SendFilename file$
 PropellerCMD 230 'Clear all the i2c registers
 For x = 1 To Len(file$)
 PropellerVAR x+1,Asc(Mid$(file$,x,1))
 Next x
 PropellerCMD 180  'Tell Propeller to copy filename from register
 PropellerCMD 181  'Tell Propeller to open the file for reading
End Sub

Sub PropellerCMD cmd
  I2C WRITE &h42,0,2,1,cmd
  Pause 100
End Sub

Sub PropellerVAR var,data
  I2C WRITE &h42,0,2,var,data
End Sub

Sub CLS
  propellerCMD 204
End Sub                                                                                 