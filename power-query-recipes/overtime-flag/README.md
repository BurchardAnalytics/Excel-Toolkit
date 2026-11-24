# Overtime flag

A timecard export shows hours by shift. Overtime is decided by the week. This recipe adds up each employee's hours for each workweek and flags every week over 40. Set it up once. After that, save the new export over the old one and click **Refresh All**.

## What it does

- **Adds up hours by employee, by week.** Split shifts and multiple rows on one day are counted together.
- **Splits each week into regular and overtime hours.** 44.5 hours becomes 40 regular and 4.5 overtime.
- **Flags every week over 40** with a Yes in the **Over 40** column.
- **Starts the week on the day you choose,** so it matches your payroll workweek.
- **Drops blank rows** and trims stray spaces from names and IDs.

## Before and after

**Before.** The sample file, `sample-data/timecard-export.csv`, has 36 rows: four employees, two weeks, one row per shift. The first lines, opened in Notepad:

```text
Employee ID,Employee,Date,Hours
E101,Dana Whitlock,11/02/2026,9
E101,Dana Whitlock,11/03/2026,9
E101,Dana Whitlock,11/04/2026,9
E101,Dana Whitlock,11/05/2026,9
E101,Dana Whitlock,11/06/2026,8
E102,Marcus Bell,11/02/2026,8
```

**After.** Eight rows: one per employee, per week. The weeks run Sunday to Saturday.

| Employee ID | Employee | Week Start | Week End | Total Hours | Regular Hours | Overtime Hours | Over 40 |
|---|---|---|---|---:|---:|---:|---|
| E101 | Dana Whitlock | 11/1/2026 | 11/7/2026 | 44 | 40 | 4 | Yes |
| E102 | Marcus Bell | 11/1/2026 | 11/7/2026 | 40 | 40 | 0 | No |
| E103 | Priya Sandoval | 11/1/2026 | 11/7/2026 | 46.5 | 40 | 6.5 | Yes |
| E104 | Theo Grant | 11/1/2026 | 11/7/2026 | 16 | 16 | 0 | No |
| E101 | Dana Whitlock | 11/8/2026 | 11/14/2026 | 40.25 | 40 | 0.25 | Yes |
| E102 | Marcus Bell | 11/8/2026 | 11/14/2026 | 44.5 | 40 | 4.5 | Yes |
| E103 | Priya Sandoval | 11/8/2026 | 11/14/2026 | 32 | 32 | 0 | No |
| E104 | Theo Grant | 11/8/2026 | 11/14/2026 | 12 | 12 | 0 | No |

Four weeks are flagged. Total Hours adds up to 275.25, the same as the Hours column in the original export. Overtime adds up to 15.25.

Marcus Bell's first week is exactly 40. That isn't overtime, so it says No. A quarter hour over, like Dana Whitlock's second week, says Yes.

## Steps

Try it on the sample file first. Then point it at your own.

You need Excel 2016 or later, or Microsoft 365, on Windows. Power Query is built in.

1. Download `sample-data/timecard-export.csv` from this repository. Save it in your Downloads folder.
2. Open `overtime-flag.pq` in this folder on GitHub. Click the **Copy raw file** button at the top right of the code (two overlapping squares).
3. Open a blank workbook in Excel.
4. Go to **Data > Get Data > From Other Sources > Blank Query**. In older Excel 2016, it's **Data > New Query > From Other Sources > Blank Query**.
5. The Power Query Editor opens. Click **Home > Advanced Editor**.
6. Delete everything in the box. Press **Ctrl+V** to paste the recipe.
7. Find the line that starts with `FilePath =`. Point it at your file:
   - In File Explorer, right-click the CSV and choose **Copy as path**. On Windows 10, hold **Shift** while you right-click.
   - Back in the editor, select everything between `FilePath = ` and the comma at the end of the line, including the quote marks.
   - Press **Ctrl+V**. The copied path brings its own quote marks.
8. Click **Done**. The preview shows one row per employee per week. With the sample file, you should see eight rows.
9. On the right, under **Query Settings**, type a name in the **Name** box, like `Overtime Flag`.
10. Click **Home > Close & Load**. The table lands on a new sheet.

Next time: save the new export with the same name, in the same place. Then go to **Data > Refresh All**.

## Use it on your own timecards

Every line you change is in the SETTINGS block at the top. Nothing below it needs touching.

| Setting | What to put there | Sample value |
|---|---|---|
| `FilePath` | Full path to your timecard CSV file | `"C:\Users\YourName\Downloads\timecard-export.csv"` |
| `EmployeeColumns` | The column or columns that identify an employee | `{"Employee ID", "Employee"}` |
| `DateColumn` | The column with the work date | `"Date"` |
| `HoursColumn` | The column with hours worked, as a number like 8.5 | `"Hours"` |
| `WeekStartsOn` | The first day of your workweek | `Day.Sunday` |
| `OvertimeAfter` | Hours in a week before overtime starts | `40` |
| `ShowOnlyOvertime` | `true` to show only the flagged weeks. `false` to show every week. | `false` |
| `Culture` | `"en-US"` for month-first dates. `"en-GB"` for day-first. | `"en-US"` |

Column names must match your header row exactly. Capitals and spaces count.

Use an employee ID if your export has one. Two people can share a name. If your export has only names, change the line to `EmployeeColumns = {"Employee"},`.

Set `WeekStartsOn` to the day your payroll week starts. If your week runs Monday to Sunday, change it to `Day.Monday`. Get this wrong and hours land in the wrong week.

Want a short list for the manager? Change `ShowOnlyOvertime` to `true`. Only the Yes rows come back.

## Check the result

Add up the Total Hours column. Compare it to the total hours in the original export. If they match, nothing was lost.

Filter **Week Start** for blanks. A blank week means a date couldn't be read. Fix it in the export, or check `Culture`.

Then pick one flagged employee and add up their week by hand. If your number matches the recipe, you can trust the rest.

## If something goes wrong

- **"Column not found."** A column name in SETTINGS doesn't match your header row. The message names the column.
- **Every week shows 0 hours.** Your hours aren't plain numbers. `8:30` or `8h 30m` won't read. Hours must look like `8.5`.
- **Dates look wrong.** November 2 shows as February 11. Your export writes day first. Change `Culture` to `"en-GB"`.
- **One employee shows up twice in the same week.** Their name or ID is spelled two ways in the export. Fix it at the source, or use the ID column only.
- **"Could not find file."** The path in `FilePath` is wrong, or the file was moved or renamed.

## What this recipe doesn't do

It flags weekly overtime from total hours. It doesn't turn clock-in and clock-out times into hours, apply daily overtime rules like California's, or figure overtime pay. Overtime law varies by state and by job. Check your state's rules and your payroll provider before you pay on it.
