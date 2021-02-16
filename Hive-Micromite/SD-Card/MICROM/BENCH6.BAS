100 Timer=0
105 k=0
108 Dim m(5)
110 Print"Start"
120 k=k+1
125 a=k/2*3+4-5
130 GoSub 600
135 For l=1 To 5
136 Next l
137 If k<1000 Then GoTo 120
150 Print Timer
155 End
600 Return                                                                