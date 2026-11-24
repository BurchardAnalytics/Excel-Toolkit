// =====================================================================
// Overtime flag
// excel-toolkit | Burchard Analytics LLC | MIT License
//
// Takes a timecard export (one row per shift or per day) and returns
// one row per employee per week:
//   - total hours for the week
//   - regular hours (up to 40) and overtime hours (over 40)
//   - a Yes/No flag for every week over 40
//
// The week runs from the day you pick in SETTINGS. Match it to your
// payroll workweek.
//
// Change only the lines in the SETTINGS block. See README.md.
// =====================================================================
let
    // ------------------ SETTINGS: change these lines ------------------

    // 1. Full path to your timecard CSV file. Keep the quote marks.
    FilePath = "C:\Users\YourName\Downloads\timecard-export.csv",

    // 2. The column or columns that identify an employee.
    //    Hours are added up for each one. An ID is safer than a name.
    EmployeeColumns = {"Employee ID", "Employee"},

    // 3. The column that holds the work date.
    DateColumn = "Date",

    // 4. The column that holds hours worked, as a number like 8.5.
    HoursColumn = "Hours",

    // 5. The first day of your workweek.
    //    Day.Sunday, Day.Monday, Day.Tuesday and so on.
    WeekStartsOn = Day.Sunday,

    // 6. Hours in a week before overtime starts.
    OvertimeAfter = 40,

    // 7. true shows only the weeks over the limit.
    //    false shows every employee and every week.
    ShowOnlyOvertime = false,

    // 8. How dates and numbers are written. "en-US" reads 11/02/2026
    //    as November 2. Use "en-GB" if your dates are day first.
    Culture = "en-US",

    // ------------------------ END OF SETTINGS -------------------------


    // ---- Helpers ----

    // Trim a cell. An empty cell becomes a true blank (null).
    CleanText = (value as any) as any =>
        if value = null then null
        else
            let trimmed = Text.Trim(Text.From(value))
            in if trimmed = "" then null else trimmed,

    // Text to number. Anything it can't read comes out blank.
    ToNumber = (value as any) as any =>
        let cleaned = CleanText(value)
        in if cleaned = null then null
           else try Number.FromText(cleaned, Culture) otherwise null,

    // Text to date. Anything it can't read comes out blank.
    ToDate = (value as any) as any =>
        let cleaned = CleanText(value)
        in if cleaned = null then null
           else try Date.FromText(cleaned, Culture) otherwise null,

    // Name of the flag column. "Over 40" when OvertimeAfter is 40.
    FlagColumn = "Over " & Text.From(OvertimeAfter),


    // ---- Steps ----

    // Read the file and use its first row as the header.
    Source = Csv.Document(
        File.Contents(FilePath),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    // Stop with a plain message if a column name in SETTINGS is wrong.
    NeededColumns = EmployeeColumns & {DateColumn, HoursColumn},
    MissingColumns = List.Difference(NeededColumns, Table.ColumnNames(Promoted)),
    Checked =
        if List.IsEmpty(MissingColumns) then Promoted
        else error ("Column not found: " & Text.Combine(MissingColumns, ", ")
            & ". Check the column names in SETTINGS."),

    // Trim the employee columns. Turn dates and hours into real
    // dates and numbers.
    Typed = Table.TransformColumns(
        Checked,
        List.Transform(EmployeeColumns, each {_, CleanText, type nullable text})
            & {
                {DateColumn, ToDate, type nullable date},
                {HoursColumn, ToNumber, type nullable number}
            }
    ),

    // Drop rows with nothing in them.
    RealRows = Table.SelectRows(
        Typed,
        each List.NonNullCount(Record.FieldValues(Record.SelectFields(_, NeededColumns))) > 0
    ),

    // Tag each row with the first day of its workweek.
    // A date that couldn't be read gives a blank week.
    WithWeek = Table.AddColumn(
        RealRows,
        "Week Start",
        each
            let workDate = Record.Field(_, DateColumn)
            in if workDate = null then null else Date.StartOfWeek(workDate, WeekStartsOn),
        type nullable date
    ),

    // Add up hours for each employee, each week.
    Grouped = Table.Group(
        WithWeek,
        EmployeeColumns & {"Week Start"},
        {{
            "Total Hours",
            each
                let total = List.Sum(List.RemoveNulls(Table.Column(_, HoursColumn)))
                in if total = null then 0 else Number.Round(total, 2),
            type number
        }}
    ),

    // Last day of the week, regular hours, overtime hours and the flag.
    WithWeekEnd = Table.AddColumn(
        Grouped,
        "Week End",
        each if [Week Start] = null then null else Date.AddDays([Week Start], 6),
        type nullable date
    ),
    WithRegular = Table.AddColumn(
        WithWeekEnd,
        "Regular Hours",
        each Number.Round(List.Min({[Total Hours], OvertimeAfter}), 2),
        type number
    ),
    WithOvertime = Table.AddColumn(
        WithRegular,
        "Overtime Hours",
        each Number.Round(List.Max({[Total Hours] - OvertimeAfter, 0}), 2),
        type number
    ),
    WithFlag = Table.AddColumn(
        WithOvertime,
        FlagColumn,
        each if [Total Hours] > OvertimeAfter then "Yes" else "No",
        type text
    ),

    // Put the columns in order and sort by week, then employee.
    Ordered = Table.SelectColumns(
        WithFlag,
        EmployeeColumns
            & {"Week Start", "Week End", "Total Hours", "Regular Hours", "Overtime Hours", FlagColumn}
    ),
    Sorted = Table.Sort(
        Ordered,
        List.Transform({"Week Start"} & EmployeeColumns, each {_, Order.Ascending})
    ),

    // Keep only the overtime weeks if you asked for that.
    Result =
        if ShowOnlyOvertime
        then Table.SelectRows(Sorted, each Record.Field(_, FlagColumn) = "Yes")
        else Sorted
in
    Result
