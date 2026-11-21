// =====================================================================
// Combine a folder of monthly files
// excel-toolkit | Burchard Analytics LLC | MIT License
//
// Points Power Query at one folder, stacks every CSV file in it into
// one table, and tags each row with its month and the file it came
// from. Drop next month's file in the folder, click Refresh All, and
// it joins the table.
//
// The month comes from the file name. Name each file starting with
// the year and month: 2026-01 Sales.csv, 2026-02 Sales.csv.
//
// Change only the lines in the SETTINGS block. See README.md.
// =====================================================================
let
    // ------------------ SETTINGS: change these lines ------------------

    // 1. Full path to the folder that holds your monthly files.
    //    Keep the quote marks. Keep only the monthly files in it.
    FolderPath = "C:\Users\YourName\Documents\monthly-sales",

    // 2. The kind of file to pick up.
    FileExtension = ".csv",

    // 3. Columns to turn into dates and numbers after stacking.
    //    Use the column names from your files' header row.
    ColumnTypes = {
        {"Date", type date},
        {"Amount", type number}
    },

    // 4. How dates and numbers are written. "en-US" reads 01/05/2026
    //    as January 5. Use "en-GB" if your dates are day first.
    Culture = "en-US",

    // ------------------------ END OF SETTINGS -------------------------


    // ---- Helpers ----

    // Read one CSV file and use its first row as the header.
    ReadFile = (content as binary) as table =>
        Table.PromoteHeaders(
            Csv.Document(content, [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
            [PromoteAllScalars = true]
        ),

    // Month from the first 7 characters of the file name.
    // "2026-01 Sales.csv" becomes January 1, 2026.
    // A file name that doesn't start with year-month gives a blank month.
    MonthFromName = (fileName as text) as nullable date =>
        try #date(
            Number.FromText(Text.Start(fileName, 4)),
            Number.FromText(Text.Middle(fileName, 5, 2)),
            1
        ) otherwise null,


    // ---- Steps ----

    // Every file in the folder (and any folders inside it).
    AllFiles = Folder.Files(FolderPath),

    // Keep only the file type you want. Skip Excel's temporary "~$" files.
    Picked = Table.SelectRows(
        AllFiles,
        each Text.Lower([Extension]) = Text.Lower(FileExtension)
            and not Text.StartsWith([Name], "~$")
    ),
    Checked =
        if Table.IsEmpty(Picked)
        then error "No matching files found. Check FolderPath and FileExtension in SETTINGS."
        else Table.Sort(Picked, {{"Name", Order.Ascending}}),

    // Read each file, then tag its rows with the month and file name.
    Tagged = Table.AddColumn(
        Checked,
        "Rows",
        each
            let
                fileName = [Name],
                month = MonthFromName(fileName),
                withFile = Table.AddColumn(ReadFile([Content]), "Source File", (row) => fileName, type text)
            in
                Table.AddColumn(withFile, "Month", (row) => month, type nullable date)
    ),

    // Stack all the files into one table. Columns line up by name.
    Stacked = Table.Combine(Tagged[Rows]),

    // Put Month and Source File first.
    Reordered = Table.ReorderColumns(
        Stacked,
        {"Month", "Source File"} & List.RemoveItems(Table.ColumnNames(Stacked), {"Month", "Source File"})
    ),

    // Turn text into dates and numbers.
    Result = Table.TransformColumnTypes(Reordered, ColumnTypes, Culture)
in
    Result
