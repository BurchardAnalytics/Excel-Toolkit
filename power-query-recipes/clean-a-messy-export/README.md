# Clean a messy export

Exports from sales, POS and accounting systems rarely come out ready to use. This recipe cleans one in a single refresh. Set it up once. After that, save the new export over the old one and click **Refresh All**.

## What it fixes

- **Stray spaces.** Before, after and doubled inside text. `  Harbor Light Bakery ` becomes `Harbor Light Bakery`.
- **Junk above the header.** Report titles and run dates are dropped.
- **Junk rows.** Blank rows, repeated header rows from page breaks, and total lines are dropped.
- **Numbers stored as text.** `$1,249.99` becomes 1249.99. `($8.50)` becomes -8.50.
- **Dates stored as text.** `01/05/2026`, `2026-01-07` and `Jan 9, 2026` all become real dates.
- **Two things in one column.** `Springfield, MD` becomes a City column and a State column.

## Before and after

**Before.** The sample file, `sample-data/messy-sales-export.csv`, opened in Notepad:

```text
Sample Supply Co. - Sales Export,,,,,,,
Run date: 11/20/2026,,,,,,,
,,,,,,,
Invoice Date,Invoice #,Customer,Location,Item,Qty,Unit Price,Total
01/05/2026,INV-1001,  Harbor Light Bakery ,"Springfield, MD",Flour 50 lb, 4 ,$32.50,$130.00
2026-01-07,INV-1002,Maple Street   Hardware,"Riverton, DE",Shop towels,12,$4.25,$51.00
"Jan 9, 2026",INV-1003,Bluegill Bait & Tackle,"Lakeside, VA",Ice chest, 1 ,"$1,249.99","$1,249.99"
,,,,,,,
01/12/2026, INV-1004 ,Harbor Light Bakery,"Springfield,MD",Sugar 25 lb,6,$18.00,$108.00
Invoice Date,Invoice #,Customer,Location,Item,Qty,Unit Price,Total
01/15/2026,INV-1005,Copper Kettle Diner,"Fairview, MD",Fryer oil,3,$41.00,$123.00
01/16/2026,INV-1006,Maple Street Hardware,"Riverton, DE",Shop towels (return),(2),$4.25,($8.50)
,,,,,,,
TOTAL,,,,,,,"$1,653.49"
```

**After.** Six real rows. Dates are dates. Numbers are numbers.

| Invoice Date | Invoice # | Customer | City | State | Item | Qty | Unit Price | Total |
|---|---|---|---|---|---|---:|---:|---:|
| 1/5/2026 | INV-1001 | Harbor Light Bakery | Springfield | MD | Flour 50 lb | 4 | 32.50 | 130.00 |
| 1/7/2026 | INV-1002 | Maple Street Hardware | Riverton | DE | Shop towels | 12 | 4.25 | 51.00 |
| 1/9/2026 | INV-1003 | Bluegill Bait & Tackle | Lakeside | VA | Ice chest | 1 | 1,249.99 | 1,249.99 |
| 1/12/2026 | INV-1004 | Harbor Light Bakery | Springfield | MD | Sugar 25 lb | 6 | 18.00 | 108.00 |
| 1/15/2026 | INV-1005 | Copper Kettle Diner | Fairview | MD | Fryer oil | 3 | 41.00 | 123.00 |
| 1/16/2026 | INV-1006 | Maple Street Hardware | Riverton | DE | Shop towels (return) | -2 | 4.25 | -8.50 |

The Total column adds up to 1,653.49. That matches the TOTAL line in the original export.

## Steps

Try it on the sample file first. Then point it at your own.

You need Excel 2016 or later, or Microsoft 365, on Windows. Power Query is built in.

1. Download `sample-data/messy-sales-export.csv` from this repository. Save it in your Downloads folder.
2. Open `clean-a-messy-export.pq` in this folder on GitHub. Click the **Copy raw file** button at the top right of the code (two overlapping squares).
3. Open a blank workbook in Excel.
4. Go to **Data > Get Data > From Other Sources > Blank Query**. In older Excel 2016, it's **Data > New Query > From Other Sources > Blank Query**.
5. The Power Query Editor opens. Click **Home > Advanced Editor**.
6. Delete everything in the box. Press **Ctrl+V** to paste the recipe.
7. Find the line that starts with `FilePath =`. Point it at your file:
   - In File Explorer, right-click the CSV and choose **Copy as path**. On Windows 10, hold **Shift** while you right-click.
   - Back in the editor, select everything between `FilePath = ` and the comma at the end of the line, including the quote marks.
   - Press **Ctrl+V**. The copied path brings its own quote marks.
8. Click **Done**. The preview shows the clean table. With the sample file, you should see six rows.
9. On the right, under **Query Settings**, type a name in the **Name** box, like `Clean Sales Export`.
10. Click **Home > Close & Load**. The clean table lands on a new sheet.

Next time: save the new export with the same name, in the same place. Then go to **Data > Refresh All**.

## Use it on your own export

Every line you change is in the SETTINGS block at the top. Nothing below it needs touching.

| Setting | What to put there | Sample value |
|---|---|---|
| `FilePath` | Full path to your CSV file | `"C:\Users\YourName\Downloads\messy-sales-export.csv"` |
| `HeaderFirstCell` | The exact text in the first cell of your header row | `"Invoice Date"` |
| `KeyColumn` | A column every real row has filled in. Rows where it's blank get dropped. | `"Invoice #"` |
| `DateColumns` | Columns that hold dates | `{"Invoice Date"}` |
| `NumberColumns` | Columns that hold numbers or dollar amounts | `{"Qty", "Unit Price", "Total"}` |
| `SplitColumn` | The column that holds two things. Use `null` to skip splitting. | `"Location"` |
| `SplitDelimiter` | The character between the two things | `","` |
| `SplitInto` | Names for the two new columns | `{"City", "State"}` |
| `Culture` | `"en-US"` for month-first dates. `"en-GB"` for day-first. | `"en-US"` |

Column names must match your header row exactly. Capitals and spaces count.

Choose `KeyColumn` with care. It decides which rows are real. An invoice number, order number or transaction ID works well. A total line leaves it blank, so the total line goes.

## Check the result

Add up a money column. Compare it to the total on the original export. If they match, nothing was lost.

A blank cell in a date or number column means the recipe couldn't read that value. Filter that column for blanks to find them. Fix them in the source, or tell the people who run the export.

## If something goes wrong

- **"Header row not found."** `HeaderFirstCell` doesn't match the first cell of your header row. Check the spelling.
- **"The column ... of the table wasn't found."** A column name in SETTINGS doesn't match your header row.
- **Dates look wrong.** January 5 shows as May 1. Your export writes day first. Change `Culture` to `"en-GB"`.
- **"Could not find file."** The path in `FilePath` is wrong, or the file was moved or renamed.

## What this recipe doesn't do

It cleans one export. It doesn't combine files, check your numbers against your books, or build a report. Those are separate jobs.
