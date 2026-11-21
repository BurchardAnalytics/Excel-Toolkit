// =====================================================================
// Clean a messy export
// excel-toolkit | Burchard Analytics LLC | MIT License
//
// Takes a CSV export from a sales, POS or accounting system and
// returns a clean table:
//   - trims stray spaces, including the doubled ones inside names
//   - drops title lines above the header, blank rows, repeated
//     header rows and total lines
//   - turns numbers and dates stored as text into real numbers
//     and dates
//   - splits one combined column (like "Springfield, MD") into two
//
// Change only the lines in the SETTINGS block. See README.md.
// =====================================================================
let
    // ------------------ SETTINGS: change these lines ------------------

    // 1. Full path to your CSV file. Keep the quote marks.
    FilePath = "C:\Users\YourName\Downloads\messy-sales-export.csv",

    // 2. The exact text in the first cell of your real header row.
    //    Everything above that row (report titles, run dates) is dropped.
    HeaderFirstCell = "Invoice Date",

    // 3. A column that every real row has filled in.
    //    Rows where it is blank (spacer rows, total lines) are dropped.
    KeyColumn = "Invoice #",

    // 4. Columns that hold dates.
    DateColumns = {"Invoice Date"},

    // 5. Columns that hold numbers or dollar amounts.
    NumberColumns = {"Qty", "Unit Price", "Total"},

    // 6. A column that holds two things, the character between them,
    //    and names for the two new columns.
    //    To skip this step, change the first line to: SplitColumn = null,
    SplitColumn = "Location",
    SplitDelimiter = ",",
    SplitInto = {"City", "State"},

    // 7. How dates and numbers are written. "en-US" reads 01/05/2026
    //    as January 5. Use "en-GB" if your dates are day first.
    Culture = "en-US",

    // ------------------------ END OF SETTINGS -------------------------


    // ---- Helpers ----

    // Clean one cell: break on any kind of space (tabs, line breaks,
    // non-breaking spaces), drop the empty pieces, rejoin with single
    // spaces, then strip any leftover hidden characters.
    // An empty cell becomes a true blank (null).
    WhiteSpace = " #(tab)#(cr)#(lf)" & Character.FromNumber(160),
    CleanText = (value as any) as any =>
        if value = null then null
        else
            let
                pieces = List.Select(Text.SplitAny(Text.From(value), WhiteSpace), each _ <> ""),
                joined = Text.Clean(Text.Combine(pieces, " "))
            in
                if joined = "" then null else joined,

    // Text to number: removes $ and commas, reads (8.50) as -8.50.
    // Anything it can't read comes out blank, so you can filter for it.
    ToNumber = (value as any) as any =>
        if value = null then null
        else
            let
                bare = Text.Remove(Text.From(value), {"$", ",", " "}),
                isNegative = Text.StartsWith(bare, "(") and Text.EndsWith(bare, ")"),
                digits = if isNegative then Text.Middle(bare, 1, Text.Length(bare) - 2) else bare,
                number = try Number.FromText(digits, Culture) otherwise null
            in
                if number = null then null else if isNegative then -number else number,

    // Text to date. Handles 01/05/2026, 2026-01-07 and Jan 9, 2026.
    // Anything it can't read comes out blank, so you can filter for it.
    ToDate = (value as any) as any =>
        if value = null then null
        else try Date.FromText(Text.From(value), Culture) otherwise null,


    // ---- Steps ----

    // Read the file as plain text, one column per field.
    Source = Csv.Document(
        File.Contents(FilePath),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),

    // Clean every cell in every column.
    Trimmed = Table.TransformColumns(
        Source,
        List.Transform(Table.ColumnNames(Source), each {_, CleanText})
    ),

    // Find the real header row and drop everything above it.
    HeaderRow = List.PositionOf(Table.Column(Trimmed, "Column1"), HeaderFirstCell),
    FromHeader =
        if HeaderRow < 0
        then error "Header row not found. Check HeaderFirstCell in SETTINGS."
        else Table.Skip(Trimmed, HeaderRow),
    Promoted = Table.PromoteHeaders(FromHeader, [PromoteAllScalars = true]),

    // Keep only real rows. A real row has the key column filled in,
    // and it isn't a copy of the header row.
    RealRows = Table.SelectRows(
        Promoted,
        each
            let key = Record.Field(_, KeyColumn)
            in key <> null and key <> KeyColumn
    ),

    // Turn text into numbers and dates.
    Numbers = Table.TransformColumns(
        RealRows,
        List.Transform(NumberColumns, each {_, ToNumber, type nullable number})
    ),
    Dates = Table.TransformColumns(
        Numbers,
        List.Transform(DateColumns, each {_, ToDate, type nullable date})
    ),

    // Split the combined column at the first delimiter, then clean
    // the two new columns.
    SplitAtFirst = Splitter.SplitTextByEachDelimiter({SplitDelimiter}, QuoteStyle.None),
    Split =
        if SplitColumn = null then Dates
        else
            Table.SplitColumn(
                Dates,
                SplitColumn,
                (value) => if value = null then {} else SplitAtFirst(value),
                SplitInto
            ),
    Result =
        if SplitColumn = null then Split
        else
            Table.TransformColumns(
                Split,
                List.Transform(SplitInto, each {_, CleanText, type nullable text})
            )
in
    Result
