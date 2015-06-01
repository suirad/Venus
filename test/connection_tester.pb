InitNetwork()
con = OpenNetworkConnection("localhost", 3000)
If Not con:Debug "Connection is null":End:EndIf
Global *buff = AllocateMemory(100)
Declare sendrcv(con,*msg,len):Declare rcv(con)
Global msg.s

msg = "register,craps"+#CRLF$
sendrcv(con,@msg,Len(msg))

msg = "msg,all,chat,my message"+#CRLF$
sendrcv(con,@msg,Len(msg))
End
SendNetworkData(con,@"msg,cifquaft,pp,msg",Len("msg,cifquaft,pp,msg"))
rcv(con)

Procedure rcv(con)
  Repeat
    Delay(10)
    If NetworkClientEvent(con) = #PB_NetworkEvent_Data
      len = ReceiveNetworkData(con,*buff,100)
      Debug PeekS(*buff,len)
    EndIf
  ForEver  
EndProcedure

Procedure sendrcv(con,*msg, mlen)
  SendNetworkData(con,*msg,mlen)
  While Not NetworkClientEvent(con)
    Delay(10)
  Wend
  len = ReceiveNetworkData(con,*buff,100)
  Debug PeekS(*buff,len)
  Delay(1000)
EndProcedure


; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 10
; Folding = -
; EnableXP