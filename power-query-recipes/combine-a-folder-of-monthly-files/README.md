# Combine a folder of monthly files

One file per month is easy to save and hard to analyze. This recipe stacks every file in a folder into one table and tags each row with its month. Set it up once. After that, drop next month's file in the folder and click **Refresh All**.

## What it does

- **Reads every CSV in one folder.** No copying and pasting between files.
- **Stacks them into one table.** Columns line up by name.
- **Tags each row with its month,** taken from the file name.
- **Tags each row with its source file,** so you can trace any number back to where it came from.
- **Turns dates and amounts into real dates and numbers** after stacking.

## Before and after

**Before.** Three files in `sample-data/monthly-sales/`, each with the same columns:

```text
2026-01 Sales.csv    4 rows
2026-02 Sales.csv    3 rows
2026-03 Sales.csv    4 rows
```

Each one looks like this:

```text
Date,Invoice #,Customer,Item,Amount
01/06/2026,INV-2001,Harbor Light Bakery,Flour 50 lb,130.00
01/14/2026,INV-2002,Maple Street Hardware,Shop towels,51.00
```

**After.** One table with 11 rows. The first five:

| Month | Source File | Date | Invoice # | Customer | Item | Amount |
|---|---|---|---|---|---|---:|
| Jan 2026 | 2026-01 Sales.csv | 1/6/2026 | INV-2001 | Harbor Light Bakery | Flour 50 lb | 130.00 |
| Jan 2026 | 2026-01 Sales.csv | 1/14/2026 | INV-2002 | Maple Street Hardware | Shop towels | 51.00 |
| Jan 2026 | 2026-01 Sales.csv | 1/22/2026 | INV-2003 | Copper Kettle Diner | Fryer oil | 123.00 |
| Jan 2026 | 2026-01 Sales.csv | 1/29/2026 | INV-2004 | Bluegill Bait & Tackle | Ice chest | 1,249.99 |
| Feb 2026 | 2026-02 Sales.csv | 2/3/2026 | INV-2005 | Copper Kettle Diner | Fryer oil | 164.00 |

Month totals: January 1,553.99. February 348.50. March 646.50.

## Rules for the folder

The recipe is simple because the folder follows three rules.

1. **Name each file starting with the year and month.** `2026-01 Sales.csv`, `2026-02 Sales.csv`. Four-digit year, dash, two-digit month. The files also sort in order this way.
2. **Use the same column names in every file.** The order can differ. A file with an extra column adds that column, and the other files show blanks in it.
3. **Keep only the monthly files in the folder.** The recipe also reads any folders inside it.

## Steps

Try it on the sample files first. Then point it at your own folder.

You need Excel 2016 or later, or Microsoft 365, on Windows. Power Query is built in.

1. Make a folder called `monthly-sales` in your Documents folder.
2. Download the three files in `sample-data/monthly-sales/` from this repository. Save them in that folder.
3. Open `combine-a-folder-of-monthly-files.pq` in this folder on GitHub. Click the **Copy raw file** button at the top right of the code (two overlapping squares).
4. Open a blank workbook in Excel.
5. Go to **Data > Get Data > From Other Sources > Blank Query**. In older Excel 2016, it's **Data > New Query > From Other Sources > Blank Query**.
6. The Power Query Editor opens. Click **Home > Advanced Editor**.
7. Delete everything in the box. Press **Ctrl+V** to paste the recipe.
8. Find the line that starts with `FolderPath =`. Point it at your folder:
   - In File Explorer, open the folder. Click the address bar at the top. Press **Ctrl+C**.
   - Back in the editor, select the text between the two quote marks on that line. Leave the quote marks.
   - Press **Ctrl+V**.
9. Click **Done**. The preview shows one stacked table. With the sample files, you should see 11 rows.
10. On the right, under **Query Settings**, type a name in the **Name** box, like `All Monthly Sales`.
11. Click **Home > Close & Load**. The combined table lands on a new sheet.
12. Optional: the Month column shows the first day of each month, like 1/1/2026. To show it as Jan 2026, select the column, press **Ctrl+1**, choose **Custom**, and type `mmm yyyy`.

Next month: save the new file in the folder, named the same way. Then go to **Data > Refresh All**.

## Use it on your own files

Every line you change is in the SETTINGS block at the top. Nothing below it needs touching.

| Setting | What to put there | Sample value |
|---|---|---|
| `FolderPath` | Full path to the folder | `"C:\Users\YourName\Documents\monthly-sales"` |
| `FileExtension` | The kind of file to pick up | `".csv"` |
| `ColumnTypes` | Columns to turn into dates and numbers, by name | `{"Date", type date}, {"Amount", type number}` |
| `Culture` | `"en-US"` for month-first dates. `"en-GB"` for day-first. | `"en-US"` |

To add a column to `ColumnTypes`, copy a line, change the name, and keep the comma between lines. Use `type date` for dates and `type number` for numbers. Leave text columns out.

## Check the result

Filter the Month column for blanks. A blank month means that file's name doesn't start with the year and month.

Then check the row count for one month against the original file. If they match, nothing was lost.

## If something goes wrong

- **"No matching files found."** The path in `FolderPath` is wrong, or the folder has no `.csv` files.
- **"The column ... of the table wasn't found."** A name in `ColumnTypes` doesn't match the header row in your files.
- **"We couldn't convert to Number."** An amount has a dollar sign, a comma or a note in it. Clean the files first with the *Clean a messy export* recipe.
- **Refresh fails on one file.** Close the monthly files in Excel before you click Refresh All.

## What this recipe doesn't do

It stacks files that are already clean and shaped the same. It doesn't fix messy exports, match columns with different names, or build a report. Those are separate jobs.
