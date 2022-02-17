Option Explicit
Option Compare Binary

Const StartRow As Long = 4
Const ConnString As String = "Provider=OraOLEDB.Oracle;Data Source=server:1521/usoi;User ID=user;Password=pwd;"

' Номер столбцов формы 7
Private Enum F7Columns
    DateCol = 1         ' Дата
    FieldCol = 2        ' Месторождение
    WellCol = 4         ' Скв/Гтс
    StateCol = 7        ' Состояние скважины
    OperCol = 8         ' Способ эксплуатации
    PbufCol = 9         ' Рбуф (min)
    PzatCol = 11        ' Рзатр (min)
    PlinCol = 13        ' Рлин (min)
    UptimeCol = 15      ' Час раб.
    PmkCol = 18         ' Рм/к (12х16)
    TempCol = 19        ' T, °С
    DensCol = 21        ' Плотность нефти, г/см3
    LiqRatCol = 22      ' Qж, м3 (Факт)
    InjRatCol = 23      ' Qппд, м3 (Факт)
    OilRatCol = 24      ' Qн, т (Факт)
    WatCutCol = 25      ' % воды
    GasRatCol = 26      ' Qгаз, м3 (Факт)
    ChokeCol = 27       ' Dшт, мм
    GorCol = 28         ' Газовый фактор, м3/т
    GasLiftCol = 29     ' Qг/л, тыс.м3
    GrafCol = 32        ' График работы
    HzatCol = 36        ' Нзатр, м
    HdkoCol = 37        ' H DKO, м
    LossCol = 38        ' Потери недоборы, тонн
    CommentCol = 41     ' Примечание
End Enum

' Коды параметров для нефтедобывающих скважин
Private Enum OilWellParamCodes
    PbufCode = 135      ' Давление буферное (ТМ)
    PzatCode = 6001     ' Давление затрубное (ТМ)
    PlinCode = 142      ' Давление линейное (ТМ)
    UptimeCode = 3011   ' Время работы (ТМ)
    TempCode = 7155     ' Температура на устье
    DensCode = 6017     ' Плотность нефти ХАЛ
    LiqRatCode = 1001   ' Дебит жидкости ручной
    OilRatCode = 7215   ' Дебит нефти (в т.ч. конденсат)
    WatCutCode = 33     ' Обводненность (ТМ)
    ChokeCode = 56      ' Диаметр штуцера
    GorCode = 7003      ' Газовый фактор по дебиту нефти с учетом конденсата
    GasLiftCode = 6002  ' Дебит газлифтного газа
    GrafCode = 186      ' Ситуация
    HdinCode = 6        ' Динамический уровень
    HstatCode = 18      ' Статический уровень жидкости
    LossCode = 165      ' Потери
    CommentCode = 25    ' Примечание
End Enum

' Коды параметров для нагнетательных скважин
Private Enum InjWellParamCodes
    PbufCode = 15       ' Давление буферное
    PzatCode = 20       ' Затрубное давление
    PmkCode = 7216      ' Давление в межколонном пространстве
    InjRatCode = 7086   ' Приемистость среднесуточная технологическая
    ChokeCode = 22      ' Диаметр штуцера
    GrafCode = 2013     ' Ситуация
    CommentCode = 25    ' Примечание
End Enum

' Коды параметров для газоконденсатных скважин
Private Enum CondWellParamCodes
    PbufCode = 126      ' Давление буферное
    PzatCode = 125      ' Затрубное давление
    PlinCode = 127      ' Давление в линии
    TempCode = 130      ' Температура на устье
    LiqRatCode = 122    ' Дебит жидкости
    OilRatCode = 131    ' Дебит стабильного конденсата
    WatCutCode = 123    ' Обводненность объемная
    GasRatCode = 132    ' Дебит сухого газа
    CommentCode = 25    ' Примечание
End Enum

' Возможные назначения скважины
Const WellPurposeOil As String = "Нефтяные"
Const WellPurposeGas As String = "Газовые"
Const WellPurposeWater As String = "Водозаборные"
Const WellPurposeGasCond As String = "Газоконденсатные"
Const WellPurposeInj As String = "Нагнетательные"

' Возможные состояния скважины
Const WellStateActive As String = "1.в работе"
Const WellStateShutin As String = "2.остановлена"
Const WellStateIdle As String = "3.в бездействии"
Const WellStateLongIdle As String = "4.в бездействии прошлых лет"
Const WellStateContruct As String = "5.в освоении"
Const WellStatePlugged As String = "6.в консервации"
Const WellStateObserve As String = "7.наблюдательная"
Const WellStateAbandonedTemp As String = "8.ликвидированная"
Const WellStateAbandonedPerm As String = "9.ликвидированная физически"

' Возможные способы эксплуатации
Const WellOperationGaslift As String = "1.Газлифт"
Const WellOperationGusher As String = "2.Фонтан"
Const WellOperationEsp As String = "3.ЭЦН"
Const WellOperationInj As String = "4.ППД"

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
        Err.Raise vbObjectError, "CalcWellId()", "Номер скважины " & wellname & " не может быть пустым"
    Else
        num = CLng(numtxt)
    End If
    
    If Not fldcoll.Exists(field) Then
        Err.Raise vbObjectError, "CalcWellId()", "Месторождение " & field & " не найдено в базе данных"
    Else
        fldcod = CLng(fldcoll(field))
    End If
    
    If Len(suffix) > 0 Then
        If Not suffixcoll.Exists(suffix) Then
            Err.Raise vbObjectError, "CalcWellId()", "Буквенный код " & suffix & " не найден в базе данных"
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
    
    ' открыть книгу
    file = Application.GetOpenFilename("Excel (*.xl*), *.xl*")
    If file = False Then Exit Sub
    Set wb = Workbooks.Open(file)
    
    sttime = Timer
    
    ' прочитать список месторождений
    row = 1
    Set sheet = ThisWorkbook.Worksheets("FIELD")
    Set fldcoll = CreateObject("Scripting.Dictionary")
    While Not IsEmpty(sheet.Cells(row, 1))
        key = sheet.Cells(row, 1).Value
        val = sheet.Cells(row, 2).Value
        fldcoll.Add key, val
        row = row + 1
    Wend
    
    ' подключиться к БД
    transact = False
    Set conn = CreateObject("ADODB.Connection")
    conn.Open ConnString
    
    ' прочитать список буквенных кодов
    Set rs = CreateObject("ADODB.Recordset")
    Set suffixcoll = CreateObject("Scripting.Dictionary")
    rs.Open "SELECT LETTER, COD FROM OILINFO.SKVCOD$", conn
    rs.MoveFirst
    While Not rs.EOF
        If IsNull(rs("LETTER").Value) Then
            Err.Raise "Буквенный код не может быть пустым"
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
    
    ' прочитать список скважин из БД
    Set rs = CreateObject("ADODB.Recordset")
    Set skvcoll = CreateObject("Scripting.Dictionary")
    rs.Open "SELECT SK_1, PROJECT_PURPOSE_NAME FROM WELLOPVSP.V_WELL_FULL_", conn
    rs.MoveFirst
    While Not rs.EOF
        If IsNull(rs("SK_1").Value) Then
            Err.Raise "Код скважины не может быть пустым"
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

    ' открыть лист
    Set sheet = wb.Worksheets("Sheet1")
    row = StartRow
    cnt = 0
    
    ' начать транзакцию
    conn.BeginTrans
    transact = True
    
    ' цикл по строкам таблицы
    While Not IsEmpty(sheet.Cells(row, DateCol))
        
        ' прочитать значения параметров
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
        
        ' преобразование единиц измерения
        If Not IsEmpty(sheet.Cells(row, GasLiftCol).Value) Then gaslift = gaslift * 1000
        
        ' преобразование времени работы в число часов
        If Not IsEmpty(sheet.Cells(row, UptimeCol).Value) Then
            pos = InStr(uptimetxt, ":")
            uptime = CDbl(Mid(uptimetxt, 1, pos - 1)) + CDbl(Mid(uptimetxt, pos + 1)) / 60
        End If
        
        ' форматирование примечания
        If Not IsEmpty(sheet.Cells(row, HdkoCol).Value) Then
            comment = state & "; " & oper & "; HDKO=" & hdko & "м; " & comment
        Else
            comment = state & "; " & oper & "; " & comment
        End If
        
        ' загрузка данных в БД в зависимости от назначения скважины
        wellid = CalcWellId(well, field, suffixcoll, fldcoll)
        If Not skvcoll.Exists(CStr(wellid)) Then

            Debug.Print "Скважина " & well & " не найдена в базе данных"

            
        Else
            purpose = skvcoll(CStr(wellid))
            Select Case purpose
            
            Case WellPurposeOil     ' нефтяные
                If oper <> WellOperationGaslift And oper <> WellOperationGusher And oper <> WellOperationEsp Then
                    Err.Raise vbObjectError, "LoadDb()", "Способ эксплуатации скважины " & well & " по форме 7 (" & oper & ") не соответствует БД (" & skvcoll(well) & ")"
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
            
            Case WellPurposeInj     ' нагнетательные
                If oper <> WellOperationInj Then
                    Err.Raise vbObjectError, "LoadDb()", "Способ эксплуатации скважины " & well & " по форме 7 (" & oper & ") не соответствует БД (" & skvcoll(well) & ")"
                End If
                
                If Not IsEmpty(sheet.Cells(row, PbufCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.PbufCode, Format(dt, "dd.mm.yyyy"), pbuf
                If Not IsEmpty(sheet.Cells(row, PzatCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.PzatCode, Format(dt, "dd.mm.yyyy"), pzat
                If Not IsEmpty(sheet.Cells(row, PmkCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.PmkCode, Format(dt, "dd.mm.yyyy"), pmk
                If Not IsEmpty(sheet.Cells(row, InjRatCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.InjRatCode, Format(dt, "dd.mm.yyyy"), injrat
                If Not IsEmpty(sheet.Cells(row, ChokeCol).Value) Then ExecDbProcNum conn, wellid, InjWellParamCodes.ChokeCode, Format(dt, "dd.mm.yyyy"), choke
                If Not IsEmpty(sheet.Cells(row, GrafCol).Value) Then ExecDbProcTxt conn, wellid, InjWellParamCodes.GrafCode, Format(dt, "dd.mm.yyyy"), graf
                ExecDbProcTxt conn, wellid, InjWellParamCodes.CommentCode, Format(dt, "dd.mm.yyyy"), comment
                cnt = cnt + 1
                
            Case WellPurposeGasCond ' газоконденсатные
                If oper <> WellOperationGusher Then
                    Err.Raise vbObjectError, "LoadDb()", "Способ эксплуатации скважины " & well & " по форме 7 (" & oper & ") не соответствует БД (" & skvcoll(well) & ")"
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
                
            Case Else               ' прочие - ничего не делать
                'Debug.Print "Скважина " & well & " (" & field & ") " & state & " " & oper & " имеет некорректное назначение " & skvcoll(well)
                
            End Select
            
        End If
        
        row = row + 1
        
    Wend
    
    ' закрыть транзакцию
    conn.CommitTrans
    transact = False
    
    ' отключиться от БД
    conn.Close
    Set conn = Nothing
    
    ' закрыть книгу
    wb.Close
    Set wb = Nothing
    
    ' вычислить время выполнения
    secduration = Round(Timer - sttime, 2)
    'Debug.Print "Загружено " & cnt & " строк за " & secduration & " секунд"
    MsgBox "Загружено " & cnt & " строк за " & secduration & " секунд"

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
