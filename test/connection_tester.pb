InitNetwork()
con = OpenNetworkConnection("localhost", 3000)
If Not con:Debug "Connection is null":End:EndIf
msg.s = "register,Civcraft"
SendNetworkData(con,@msg,Len(msg))
*buff = AllocateMemory(100)
Repeat
  If NetworkClientEvent(con) = #PB_NetworkEvent_Data
    len = ReceiveNetworkData(con,*buff,100)
    Debug "Got: "+PeekS(*buff,len)
    msg = "Test"
    Delay(1000)
    SendNetworkData(con,@msg,Len(msg))
    Delay(1000)
    End
  EndIf
  Delay(10)
  ForEver
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 13
; EnableXP