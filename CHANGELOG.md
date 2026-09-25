# Changelog

## 0.1.0

First release.

- Formula language: hand-written lexer, recursive descent parser and a sealed AST, with
  arithmetic, comparison and concatenation operators, cell and range references, cross-sheet
  references (`Data!A1`, `'My Sheet'!A1:B3`) and workbook-wide defined names.
- 138 built-in functions (141 names including the `AVG`, `CEILING` and `CONCATENATE` aliases) in
  nine groups: math, aggregate and conditional, statistics, text, logical, information, lookup,
  date and financial.
- Dependency graph across sheets: an edit recomputes only the cells that depend on it, in
  topological order; circular references evaluate to `#CYCLE!` instead of looping.
- Number formats (fixed, thousands, percent, currency, scientific) applied per cell and through
  `TEXT()`.
- CSV import and export (RFC 4180 quoting) for computed values and raw formulas.
- JSON workbook format with sheets, cell formats and defined names.
- Data tables over a sheet range: sort, filter, select, group by with aggregations, pivot.
- Invoices: integer money arithmetic, VAT rates and per-rate summary, line discounts, reporting
  currency, numbering sequences, JSON loading and saving, text and HTML rendering.
- `cellar` command line tool with `sheet`, `workbook`, `invoice` and `functions` commands.
