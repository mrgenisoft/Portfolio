Option Explicit
Option Compare Binary

Const StartRow As Long = 4
Const ConnString As String = "Provider=OraOLEDB.Oracle;Data Source=server:1521/usoi;User ID=user;Password=pwd;"

' ����� �������� ����� 7
Private Enum F7Columns
    DateCol = 1         ' ����
    FieldCol = 2        ' �������������
    WellCol = 4         ' ���/���
    StateCol = 7        ' ��������� ��������
    OperCol = 8         ' ������ ������������
    PbufCol = 9         ' ���� (min)
    PzatCol = 11        ' ����� (min)
    PlinCol = 13        ' ���� (min)
    UptimeCol = 15      ' ��� ���.
    PmkCol = 18         ' ��/� (12�16)
    TempCol = 19        ' T, ��
    DensCol = 21        ' ��������� �����, �/��3
    LiqRatCol = 22      ' Q�, �3 (����)
    InjRatCol = 23      ' Q���, �3 (����)
    OilRatCol = 24      ' Q�, � (����)
    WatCutCol = 25      ' % ����
    GasRatCol = 26      ' Q���, �3 (����)
    ChokeCol = 27       ' D��, ��
    GorCol = 28         ' ������� ������, �3/�
    GasLiftCol = 29     ' Q�/�, ���.�3
    GrafCol = 32        ' ������ ������
    HzatCol = 36        ' �����, �
    HdkoCol = 37        ' H DKO, �
    LossCol = 38        ' ������ ��������, ����
    CommentCol = 41     ' ����������
End Enum

' ���� ���������� ��� ��������������� �������
Private Enum OilWellParamCodes
    PbufCode = 135      ' �������� �������� (��)
    PzatCode = 6001     ' �������� ��������� (��)
    PlinCode = 142      ' �������� �������� (��)
    UptimeCode = 3011   ' ����� ������ (��)
    TempCode = 7155     ' ����������� �� �����
    DensCode = 6017     ' ��������� ����� ���
    LiqRatCode = 1001   ' ����� �������� ������
    OilRatCode = 7215   ' ����� ����� (� �.�. ���������)
    WatCutCode = 33     ' ������������� (��)
    ChokeCode = 56      ' ������� �������
    GorCode = 7003      ' ������� ������ �� ������ ����� � ������ ����������
    GasLiftCode = 6002  ' ����� ����������� ����
    GrafCode = 186      ' ��������
    HdinCode = 6        ' ������������ �������
    HstatCode = 18      ' ����������� ������� ��������
    LossCode = 165      ' ������
    CommentCode = 25    ' ����������
End Enum

' ���� ���������� ��� �������������� �������
Private Enum InjWellParamCodes
    PbufCode = 15       ' �������� ��������
    PzatCode = 20       ' ��������� ��������
    PmkCode = 7216      ' �������� � ����������� ������������
    InjRatCode = 7086   ' ������������ �������������� ���������������
    ChokeCode = 22      ' ������� �������
    GrafCode = 2013     ' ��������
    CommentCode = 25    ' ����������
End Enum

' ���� ���������� ��� ���������������� �������
Private Enum CondWellParamCodes
    PbufCode = 126      ' �������� ��������
    PzatCode = 125      ' ��������� ��������
    PlinCode = 127      ' �������� � �����
    TempCode = 130      ' ����������� �� �����
    LiqRatCode = 122    ' ����� ��������
    OilRatCode = 131    ' ����� ����������� ����������
    WatCutCode = 123    ' ������������� ��������
    GasRatCode = 132    ' ����� ������ ����
    CommentCode = 25    ' ����������
End Enum

' ��������� ���������� ��������
Const WellPurposeOil As String = "��������"
Const WellPurposeGas As String = "�������"
Const WellPurposeWater As String = "������������"
Const WellPurposeGasCond As String = "����������������"
Const WellPurposeInj As String = "��������������"

' ��������� ��������� ��������
Const WellStateActive As String = "1.� ������"
Const WellStateShutin As String = "2.�����������"
Const WellStateIdle As String = "3.� �����������"
Const WellStateLongIdle As String = "4.� ����������� ������� ���"
Const WellStateContruct As String = "5.� ��������"
Const WellStatePlugged As String = "6.� �����������"
Const WellStateObserve As String = "7.��������������"
Const WellStateAbandonedTemp As String = "8.���������������"
Const WellStateAbandonedPerm As String = "9.��������������� ���������"

' ��������� ������� ������������
Const WellOperationGaslift As String = "1.�������"
Const WellOperationGusher As String = "2.������"
Const WellOperationEsp As String = "3.���"
Const WellOperationInj As String = "4.���"

' ADODB connection state flags
Const adStateClosed As Long = 0 'Indicates that the object is closed.
Const adStateOpen As Long = 1 'Indicates that the object is open.
Const adStateConnecting As Long = 2 'Indicates that the object is connecting.
Const adStateExecuting As Long = 4 'Indicates that the object is executing a command.
Const adStateFetching As Long = 8 'Indicates that the rows of the object are being retrieved.

' ADODB execute options
Const adAsyncExecute As Long = &H10 'Indicates that the command should execute asynchronously.
Const adAsyncFetch As Long = &H20 'Indicates that the remaining rows after the initial quantity specified in the CacheSize property should be retrieved asynchronously.
Const adAsyncFetchNonBlocking As Long = &H40 'Indicates that the main thread never blocks while retrieving. If the requested row has not been retrieved, the current row automatically moves to the end of the file.
Const adExecuteNoRecords As Long = &H80 'Indicates that the command text is a command or stored procedure that does not return rows (for example, a command that only inserts data). If any rows are retrieved, they are discarded and not returned.
Const adExecuteStream As Long = &H400 'Indicates that the results of a command execution should be returned as a stream.
Const adExecuteRecord As Long = &H800 'Indicates that the CommandText is a command or stored procedure that returns a single row which should be returned as a Record object.
Const adOptionUnspecified As Long = -1 'Indicates that the command is unspecified.

'Function Contains(coll As Collection, key As Variant) As Boolean
'    On Error Resume Next
'    coll (key) ' Just try it. If it fails, Err.Number will be nonzero.
'    Contains = (Err.Number = 0)
'    Err.Clear
'End Function

Function RegExpExtract(Text As String, Pattern As String, Optional Item As Integer = 1) As String
    On Error GoTo EH
    Dim regex As Object, matches As Object
    Set regex = CreateObject("VBScript.RegExp")
    regex.Pattern = Pattern
    regex.Global = True
    If regex.Test(Text) Then
        Set matches = regex.Execute(Text)
        RegExpExtract = matches.Item(Item - 1)
    Else
        RegExpExtract = ""
    End If
    Exit Function
EH: ' Error Handler
    'RegExpExtract = CVErr(xlErrValue)
    Err.Raise Err.Number, Err.Source, Err.Description
End Function

Sub ExecDbProcNum(conn As Object, wellid As Long, code As Long, dt As String, val As Double)

    Dim sql As String

    sql = "BEGIN " & _
          "pkg_well_measure.update_measure ( " & _
          "in_well_id => " & wellid & ", " & _
          "in_measure_type => " & code & ", " & _
          "in_measure_date => TO_DATE('" & dt & "','dd.mm.yyyy'), " & _
          "in_measure => " & Replace(CStr(val), ",", ".") & ", " & _
          "in_source => 2, " & _
          "auto_commit => pkg_well_measure.db_false); " & _
          "END;"

    conn.Execute sql, , adExecuteNoRecords
    
End Sub

Sub ExecDbProcTxt(conn As Object, wellid As Long, code As Long, dt As String, val As String)

    Dim sql As String

    sql = "BEGIN " & _
          "pkg_well_measure.update_measure_txt ( " & _
          "wellid => " & wellid & ", " & _
          "measuretype => " & code & ", " & _
          "indt => TO_DATE('" & dt & "','dd.mm.yyyy'), " & _
          "invalue => '" & Replace(val, "'", "") & "', " & _
          "intxtvalue => '" & Replace(val, "'", "") & "', " & _
          "auto_commit => pkg_well_measure.db_false); " & _
          "END;"

    conn.Execute sql, , adExecuteNoRecords
    
End Sub

Function CalcWellId(ByVal wellname As String, field As String, ByRef suffixcoll As Object, ByRef fldcoll As Object) As Long
    
    Dim numtxt As String, suffix As String
    Dim num As Long, suffixcod As Long, fldcod As Long
    
    wellname = Mid(wellname, 1, InStr(wellname, "/") - 1)
    numtxt = RegExpExtract(wellname, "\d+")
    suffix = RegExpExtract(wellname, "\D+$")
    
    If Len(numtxt) = 0 Then
        Err.Raise vbObjectError, "CalcWellId()", "����� �������� " & wellname & " �� ����� ���� ������"
    Else
        num = CLng(numtxt)
    End If
    
    If Not fldcoll.Exists(field) Then
        Err.Raise vbObjectError, "CalcWellId()", "������������� " & field & " �� ������� � ���� ������"
    Else
        fldcod = CLng(fldcoll(field))
    End If
    
    If Len(suffix) > 0 Then
        If Not suffixcoll.Exists(suffix) Then
            Err.Raise vbObjectError, "CalcWellId()", "��������� ��� " & suffix & " �� ������ � ���� ������"
        Else
            suffixcod = CLng(suffixcoll(suffix))
        End If
    Else
        suffixcod = 0
    End If
    
    CalcWellId = fldcod * 10000000 + num * 100 + suffixcod
    
End Function

Sub LoadDb()
    'On Error GoTo EH
    
    Dim conn As Object, rs As Object
    Dim transact As Boolean
    Dim sql As String
    
    Dim suffixcoll As Object, fldcoll As Object, skvcoll As Object
    Dim key As String, val As String
    
    Dim sttime As Double, secduration As Double
    Dim file As Variant, wb As Workbook, sheet As Worksheet
    Dim row As Long, wellid As Long, pos As Long, cnt As Long
    Dim dt As Date
    Dim field As String, well As String, state As String, oper As String, graf As String, comment As String, uptimetxt As String
    Dim pbuf As Double, pzat As Double, plin As Double, pmk As Double, temp As Double, dens As Double, choke As Double, uptime As Double
    Dim liqrat As Double, injrat As Double, oilrat As Double, watcut As Double, gasrat As Double, gaslift As Double, gor As Double
    Dim hzat As Double, hdko As Double, loss As Double, purpose As String
    
    ' ������� �����
    file = Application.GetOpenFilename("Excel (*.xl*), *.xl*")
    If file = False Then Exit Sub
    Set wb = Workbooks.Open(file)
    
    sttime = Timer
    
    ' ��������� ������ �������������
    row = 1
    Set sheet = ThisWorkbook.Worksheets("FIELD")
    Set fldcoll = CreateObject("Scripting.Dictionary")
    While Not IsEmpty(sheet.Cells(row, 1))
        key = sheet.Cells(row, 1).Value
        val = sheet.Cells(row, 2).Value
        fldcoll.Add key, val
        row = row + 1
    Wend
    
    ' ������������ � ��
    transact = False
    Set conn = CreateObject("ADODB.Connection")
    conn.Open ConnString
    
    ' ��������� ������ ��������� �����
    Set rs = CreateObject("ADODB.Recordset")
    Set suffixcoll = CreateObject("Scripting.Dictionary")
    rs.Open "SELECT LETTER, COD FROM OILINFO.SKVCOD$", conn
    rs.MoveFirst
    While Not rs.EOF
        If IsNull(rs("LETTER").Value) Then
            Err.Raise "��������� ��� �� ����� ���� ������"
        Else
            key = rs("LETTER").Value
        End If
        If IsNull(rs("COD").Value) Then
            val = ""
        Else
            val = rs("COD").Value
        End If
        suffixcoll.Add key, val
        rs.MoveNext
    Wend
    rs.Close
    Set rs = Nothing
    
    ' ��������� ������ ������� �� ��
    Set rs = CreateObject("ADODB.Recordset")
    Set skvcoll = CreateObject("Scripting.Dictionary")
    rs.Open "SELECT SK_1, PROJECT_PURPOSE_NAME FROM WELLOPVSP.V_WELL_FULL_", conn
    rs.MoveFirst
    While Not rs.EOF
        If IsNull(rs("SK_1").Value) Then
            Err.Raise "��� �������� �� ����� ���� ������"
        Else
            key = rs("SK_1").Value
        End If
        If IsNull(rs("PROJECT_PURPOSE_NAME").Value) Then
            val = ""
        Else
            val = rs("PROJECT_PURPOSE_NAME").Value
        End If
        skvcoll.Add key, val
        rs.MoveNext
    Wend
    rs.Close
    Set rs = Nothing

    ' ������� ����
    Set sheet = wb.Worksheets("Sheet1")
    row = StartRow
    cnt = 0
    
    ' ������ ����������
    conn.BeginTrans
    transact = True
    
    ' ���� �� ������� �������
    While Not IsEmpty(sheet.Cells(row, DateCol))
        
        ' ��������� �������� ����������
        dt = sheet.Cells(row, DateCol).Value
        field = sheet.Cells(row, FieldCol).Value
        well = sheet.Cells(row, WellCol).Value
        state = sheet.Cells(row, StateCol).Value
        oper = sheet.Cells(row, OperCol).Value
        pbuf = sheet.Cells(row, PbufCol).Value
        pzat = sheet.Cells(row, PzatCol).Value
        plin = sheet.Cells(row, PlinCol).Value
        pmk = sheet.Cells(row, PmkCol).Value
        uptimetxt = sheet.Cells(row, UptimeCol).Value
        temp = sheet.Cells(row, TempCol).Value
        dens = sheet.Cells(row, DensCol).Value
        liqrat = sheet.Cells(row, LiqRatCol).Value
        injrat = sheet.Cells(row, InjRatCol).Value
        oilrat = sheet.Cells(row, OilRatCol).Value
        watcut = sheet.Cells(row, WatCutCol).Value
        gasrat = sheet.Cells(row, GasRatCol).Value
        choke = sheet.Cells(row, ChokeCol).Value
        gor = sheet.Cells(row, GorCol).Value
        gaslift = sheet.Cells(row, GasLiftCol).Value
        graf = sheet.Cells(row, GrafCol).Value
        hzat = sheet.Cells(row, HzatCol).Value
        hdko = sheet.Cells(row, HdkoCol).Value
        loss = sheet.Cells(row, LossCol).Value
        comment = sheet.Cells(row, CommentCol).Value
        
        ' �������������� ������ ���������
        If Not IsEmpty(sheet.Cells(row, GasLiftCol).Value) Then gaslift = gaslift * 1000
        
        ' �������������� ������� ������ � ����� �����
        If Not IsEmpty(sheet.Cells(row, UptimeCol).Value) Then
            pos = InStr(uptimetxt, ":")
            uptime = CDbl(Mid(uptimetxt, 1, pos - 1)) + CDbl(Mid(uptimetxt, pos + 1)) / 60
        End If
        
        ' �������������� ����������
        If Not IsEmpty(sheet.Cells(row, HdkoCol).Value) Then
            comment = state & "; " & oper & "; HDKO=" & hdko & "�; " & comment
        Else
            comment = state & "; " & oper & "; " & comment
        End If
        
        ' �������� ������ � �� � ����������� �� ���������� ��������
        wellid = CalcWellId(well, field, suffixcoll, fldcoll)
        If Not skvcoll.Exists(CStr(wellid)) Then

            Debug.Print "�������� " & well & " �� ������� � ���� ������"

            
        Else
            purpose = skvcoll(CStr(wellid))
            Select Case purpose
            
            Case WellPurposeOil     ' ��������
                If oper <> WellOperationGaslift And oper <> WellOperationGusher And oper <> WellOperationEsp Then
                    Err.Raise vbObjectError, "LoadDb()", "������ ������������ �������� " & well & " �� ����� 7 (" & oper & ") �� ������������� �� (" & skvcoll(well) & ")"
                End If
                
                If Not IsEmpty(sheet.Cells(row, PbufCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.PbufCode, Format(dt, "dd.mm.yyyy"), pbuf
                If Not IsEmpty(sheet.Cells(row, PzatCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.PzatCode, Format(dt, "dd.mm.yyyy"), pzat
                If Not IsEmpty(sheet.Cells(row, PlinCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.PlinCode, Format(dt, "dd.mm.yyyy"), plin
                If Not IsEmpty(sheet.Cells(row, UptimeCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.UptimeCode, Format(dt, "dd.mm.yyyy"), uptime
                If Not IsEmpty(sheet.Cells(row, TempCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.TempCode, Format(dt, "dd.mm.yyyy"), temp
                If Not IsEmpty(sheet.Cells(row, DensCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.DensCode, Format(dt, "dd.mm.yyyy"), dens
                If Not IsEmpty(sheet.Cells(row, LiqRatCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.LiqRatCode, Format(dt, "dd.mm.yyyy"), liqrat
                If Not IsEmpty(sheet.Cells(row, OilRatCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.OilRatCode, Format(dt, "dd.mm.yyyy"), oilrat
                If Not IsEmpty(sheet.Cells(row, WatCutCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.WatCutCode, Format(dt, "dd.mm.yyyy"), watcut
                If Not IsEmpty(sheet.Cells(row, ChokeCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.ChokeCode, Format(dt, "dd.mm.yyyy"), choke
                If Not IsEmpty(sheet.Cells(row, GorCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.GorCode, Format(dt, "dd.mm.yyyy"), gor
                If Not IsEmpty(sheet.Cells(row, GasLiftCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.GasLiftCode, Format(dt, "dd.mm.yyyy"), gaslift
                If state = WellStateActive Or state = WellStateContruct Then
                    If Not IsEmpty(sheet.Cells(row, HzatCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.HdinCode, Format(dt, "dd.mm.yyyy"), hzat
                Else
                    If Not IsEmpty(sheet.Cells(row, HzatCol).Value) Then ExecDbProcNum conn, wellid, OilWellParamCodes.HstatCode, Format(dt, "dd.mm.yyyy"), hzat
                End If
                If Not IsEmpty(sheet.Cells(row, GrafCol).Value) Then ExecDbProcTxt conn, wellid, OilWellParamCodes.GrafCode, Format(dt, "dd.mm.yyyy"), graf
                If Not IsEmpty(sheet.Cells(row, LossCol).Value) Then ExecDbProcTxt conn, wellid, OilWellParamCodes.LossCode, Format(dt, "dd.mm.yyyy"), CStr(loss)
                ExecDbProcTxt conn, wellid, OilWellParamCodes.CommentCode, Format(dt, "dd.mm.yyyy"), comment
                cnt = cnt + 1
            
            Case WellPurposeInj     ' ��������������
                If oper <> WellOperationInj Then
                    Err.Raise vbObjectError, "LoadDb()", "������ ������������ �������� " & well & " �� ����� 7 (" & oper & ") �� ������������� �� (" & skvcoll(well) & ")"
                End If
                
                If Not IsEmpty(sheet.Cells(row, PbufCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.PbufCode, Format(dt, "dd.mm.yyyy"), pbuf
                If Not IsEmpty(sheet.Cells(row, PzatCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.PzatCode, Format(dt, "dd.mm.yyyy"), pzat
                If Not IsEmpty(sheet.Cells(row, PmkCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.PmkCode, Format(dt, "dd.mm.yyyy"), pmk
                If Not IsEmpty(sheet.Cells(row, InjRatCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.InjRatCode, Format(dt, "dd.mm.yyyy"), injrat
                If Not IsEmpty(sheet.Cells(row, ChokeCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.ChokeCode, Format(dt, "dd.mm.yyyy"), choke
                If Not IsEmpty(sheet.Cells(row, GrafCol).Value) Then ExecDbProcTxt conn, wellid, InjWellParamCodes.GrafCode, Format(dt, "dd.mm.yyyy"), graf
                ExecDbProcTxt conn, wellid, InjWellParamCodes.CommentCode, Format(dt, "dd.mm.yyyy"), comment
                cnt = cnt + 1
                
            Case WellPurposeGasCond ' ����������������
                If oper <> WellOperationGusher Then
                    Err.Raise vbObjectError, "LoadDb()", "������ ������������ �������� " & well & " �� ����� 7 (" & oper & ") �� ������������� �� (" & skvcoll(well) & ")"
                End If
                
                If Not IsEmpty(sheet.Cells(row, PbufCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.PbufCode, Format(dt, "dd.mm.yyyy"), pbuf
                If Not IsEmpty(sheet.Cells(row, PzatCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.PzatCode, Format(dt, "dd.mm.yyyy"), pzat
                If Not IsEmpty(sheet.Cells(row, PlinCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.PlinCode, Format(dt, "dd.mm.yyyy"), plin
                If Not IsEmpty(sheet.Cells(row, TempCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.TempCode, Format(dt, "dd.mm.yyyy"), temp
                If Not IsEmpty(sheet.Cells(row, LiqRatCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.LiqRatCode, Format(dt, "dd.mm.yyyy"), liqrat
                If Not IsEmpty(sheet.Cells(row, OilRatCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.OilRatCode, Format(dt, "dd.mm.yyyy"), oilrat
                If Not IsEmpty(sheet.Cells(row, WatCutCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.WatCutCode, Format(dt, "dd.mm.yyyy"), watcut
                If Not IsEmpty(sheet.Cells(row, GasRatCol).Value) Then ExecDbProcNum conn, wellid, CondWellParamCodes.GasRatCode, Format(dt, "dd.mm.yyyy"), gasrat
                ExecDbProcTxt conn, wellid, CondWellParamCodes.CommentCode, Format(dt, "dd.mm.yyyy"), comment
                cnt = cnt + 1
                
            Case Else               ' ������ - ������ �� ������
                'Debug.Print "�������� " & well & " (" & field & ") " & state & " " & oper & " ����� ������������ ���������� " & skvcoll(well)
                
            End Select
            
        End If
        
        row = row + 1
        
    Wend
    
    ' ������� ����������
    conn.CommitTrans
    transact = False
    
    ' ����������� �� ��
    conn.Close
    Set conn = Nothing
    
    ' ������� �����
    wb.Close
    Set wb = Nothing
    
    ' ��������� ����� ����������
    secduration = Round(Timer - sttime, 2)
    'Debug.Print "��������� " & cnt & " ����� �� " & secduration & " ������"
    MsgBox "��������� " & cnt & " ����� �� " & secduration & " ������"

    Exit Sub
    
EH: ' Error Handler
    If Not conn Is Nothing Then
        If conn.state = adStateOpen Then
            If Not rs Is Nothing Then
                If rs.state = adStateOpen Then
                    rs.Close
                End If
                Set rs = Nothing
            End If
            If transact = True Then
                conn.RollbackTrans
            End If
            conn.Close
        End If
        Set conn = Nothing
    End If
    If Not wb Is Nothing Then
        wb.Close
        Set wb = Nothing
    End If
    'Debug.Print Err.Source & ": " & Err.Description
    MsgBox Err.Description, vbCritical, Err.Source
End Sub
