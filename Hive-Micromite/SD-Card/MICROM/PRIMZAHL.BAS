n=1
Do
skip:
   n=n+2
   For d=3 To Sqr(n)
    If Inkey$<>"" Then End
    If n Mod d=0 Then GoTo skip
   Next d
   Print n;" ";
Loop                                                                                                                   