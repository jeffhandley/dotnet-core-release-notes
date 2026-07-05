# Entity Framework Core in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new Entity Framework Core features and improvements:

<!-- toc -->

- [Full Outer Join support](#full-outer-join-support)
- [SQL Server JSON column indexes](#sql-server-json-column-indexes)
- [Keys and indexes on complex-type properties](#keys-and-indexes-on-complex-type-properties)
- [Unconstrained foreign key relationships](#unconstrained-foreign-key-relationships)
- [Wildcard support in migration operations](#wildcard-support-in-migration-operations)
- [EF1003 analyzer: raw SQL string concatenation detection](#ef1003-analyzer-raw-sql-string-concatenation-detection)
- [LINQ improvements](#linq-improvements)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

EF Core updates in .NET 11:

- [What's new in EF Core 11](https://learn.microsoft.com/ef/core/what-is-new/ef-core-11.0/whatsnew)

## Full Outer Join support

LINQ queries can now generate SQL `FULL OUTER JOIN` clauses
([dotnet/efcore #37633](https://github.com/dotnet/efcore/pull/37633)).

Previously, EF Core could emit `INNER JOIN`, `LEFT JOIN`, and `RIGHT JOIN`,
but a query that requires rows from both sides even when there is no match
forced you to fall back to raw SQL. The new support maps LINQ expressions
to a `FULL OUTER JOIN` automatically:

```csharp
var results = context.Employees
    .FullJoin(context.Projects,
        e => e.ProjectId, p => p.Id,
        (e, p) => new { Employee = e, Project = p });
```

This generates:

```sql
SELECT e.*, p.*
FROM Employees e
FULL OUTER JOIN Projects p ON e.ProjectId = p.Id
```

The feature is available for SQL Server, PostgreSQL, and SQLite.

## SQL Server JSON column indexes

EF Core can now create indexes on JSON column properties for SQL Server
([dotnet/efcore #38302](https://github.com/dotnet/efcore/pull/38302)).

SQL Server 2022+ supports indexing of values inside JSON columns.
You can configure these indexes in EF Core using the `HasIndex` fluent API:

```csharp
modelBuilder.Entity<Product>()
    .HasIndex(p => p.Details.Price)
    .IsJson();   // maps to a SQL Server JSON index expression
```

This enables efficient range queries and sorted access over JSON property
values without materializing the full JSON document.

## Keys and indexes on complex-type properties

EF Core now supports defining keys and indexes that navigate through
complex-type (owned entity) properties
([dotnet/efcore #38192](https://github.com/dotnet/efcore/pull/38192)).

Complex types are non-entity value objects embedded in a table row.
Previously you could not use their properties as key or index members.
Preview 6 lifts that restriction:

```csharp
modelBuilder.Entity<Order>()
    .HasKey(o => new { o.Address.Street, o.Address.City });

modelBuilder.Entity<Order>()
    .HasIndex(o => o.Address.PostalCode);
```

## Unconstrained foreign key relationships

EF Core now supports defining "unconstrained" foreign key relationships —
relationships where the foreign key column exists in the schema but is not
enforced as a primary or alternate key constraint on the principal
([dotnet/efcore #38361](https://github.com/dotnet/efcore/pull/38361)).

This is useful when mapping to legacy databases where referential integrity is
maintained by the application rather than by the database:

```csharp
modelBuilder.Entity<Invoice>()
    .HasOne(i => i.Customer)
    .WithMany(c => c.Invoices)
    .HasForeignKey(i => i.CustomerCode)
    .IsUnconstrained();
```

## Wildcard support in migration operations

`GetMigrations`, `ScriptMigration`, and `DropDatabase` now accept `*` as a
wildcard migration identifier
([dotnet/efcore #38327](https://github.com/dotnet/efcore/pull/38327)).

This is primarily useful when calling the EF CLI tools. For example:

```bash
dotnet ef migrations script --from * --to 20260601_AddNewTable
```

Previously you had to specify the exact migration name for `--from` and
`--to`; `*` now means "the beginning of the migration history" (for `--from`)
or "the latest applied migration" (for `--to`).

Thanks [@tebeco](https://github.com/tebeco) for the contribution.

## EF1003 analyzer: raw SQL string concatenation detection

A new `EF1003` Roslyn analyzer detects uses of `string.Format` or
`string.Concat` inside raw SQL API calls such as `FromSql` and
`ExecuteSql`
([dotnet/efcore #38208](https://github.com/dotnet/efcore/pull/38208)).

`string.Format`/`string.Concat` do not parameterize query values, so they
create SQL injection risks when the arguments come from user input. The
analyzer flags these calls at compile time:

```csharp
// EF1003 warning: string.Format in raw SQL — use parameterized FormattableString instead
var name = userInput;
context.Products.FromSql($"SELECT * FROM Products WHERE Name = " + name);
```

Use FormattableString interpolation (`$"..."` overloads) to pass parameters
safely. The analyzer is emitted as a warning that can be upgraded to an error
in projects that adopt strict SQL-injection hygiene.

Thanks [@ChristopherHaws](https://github.com/ChristopherHaws) for the contribution.

## LINQ improvements

### `List<T>.Exists` translates to `Queryable.Any`

`List<T>.Exists(predicate)` inside a LINQ query now translates to a SQL
`EXISTS` clause, matching the behavior of `Queryable.Any`
([dotnet/efcore #38226](https://github.com/dotnet/efcore/pull/38226)).

```csharp
var orders = context.Orders
    .Where(o => o.Items.Exists(i => i.Price > 100))
    .ToList();
// Previously: evaluated in memory. Now: WHERE EXISTS (SELECT 1 FROM Items ...)
```

Thanks [@chtdelia](https://github.com/chtdelia) for the contribution.

### `string.Join`/`string.Concat` with ordering on SQLite

`string.Join` and `string.Concat` aggregates can now include an `OrderBy`
clause on SQLite
([dotnet/efcore #38344](https://github.com/dotnet/efcore/pull/38344)).

```csharp
var tags = context.Products
    .Select(p => string.Join(", ", p.Tags.OrderBy(t => t.Name)))
    .ToList();
```

### Cosmos DB: `Any()` translates to `LIMIT 1`

Top-level `Any()` queries on Azure Cosmos DB now generate `LIMIT 1` instead
of an `EXISTS` subquery, which is more efficient for the Cosmos DB query
engine
([dotnet/efcore #38297](https://github.com/dotnet/efcore/pull/38297)).

### `UInt128` support in SQLite

SQLite's `SqliteValueBinder` now supports `UInt128` values, enabling you to
store and retrieve 128-bit unsigned integers in SQLite databases
([dotnet/efcore #37492](https://github.com/dotnet/efcore/pull/37492)).

Thanks [@sebastienros](https://github.com/sebastienros) for the contribution.

### Null propagation eliminates redundant `IS NOT NULL` checks

EF Core now uses null propagation to optimize away redundant `IS NOT NULL`
checks in generated SQL
([dotnet/efcore #34127](https://github.com/dotnet/efcore/pull/34127)).

When EF Core can determine statically that a value is non-null — for example,
a required property or a non-nullable navigation — it no longer emits an
`IS NOT NULL` guard in the SQL output. This produces cleaner, shorter SQL
for queries involving required properties and reduces query plan complexity:

```csharp
// The generated SQL no longer includes unnecessary IS NOT NULL checks
// when the property is required/non-nullable
var products = context.Products
    .Where(p => p.Name.Contains("Widget"))
    .ToList();
// Before: WHERE p.Name IS NOT NULL AND p.Name LIKE '%Widget%'
// After:  WHERE p.Name LIKE '%Widget%'
```

### Runtime constants in precompiled queries

Precompiled queries now support runtime constants
([dotnet/efcore #38430](https://github.com/dotnet/efcore/pull/38430)).

Previously, parameters that varied between executions had to be passed as
LINQ parameters. With runtime constant support, values that are constant
within the scope of a single EF Core context lifetime can be inlined directly
into precompiled query plans, enabling more efficient query plan reuse without
requiring a parameterized variant for each unique value.

### Cosmos DB: improved cast and convert support

EF Core's Azure Cosmos DB provider now correctly translates `CAST` and
`CONVERT` operations in LINQ queries
([dotnet/efcore #35000](https://github.com/dotnet/efcore/pull/35000)).

Previously, numeric type conversions inside Cosmos DB queries fell back to
client-side evaluation. EF Core now emits the appropriate Cosmos DB SQL
conversion functions, keeping the conversion work server-side and avoiding
unnecessary data transfer.

## Bug fixes

- Fixed `ExecuteUpdate` returning -1 (indicating 0 rows affected) on open
  connections for SQL Server when `SET NOCOUNT ON` is active. EF Core now
  explicitly sets `NOCOUNT OFF` before executing to ensure accurate row counts
  ([dotnet/efcore #37827](https://github.com/dotnet/efcore/pull/37827)).
- Fixed `GroupBy().Select(entity)` followed by a second projection producing
  incorrect SQL
  ([dotnet/efcore #38436](https://github.com/dotnet/efcore/pull/38436)).
- Fixed `NullReferenceException` materializing JSON owned collections with
  nested primitive collections under lazy-loading proxies
  ([dotnet/efcore #38473](https://github.com/dotnet/efcore/pull/38473)).
- Fixed `NullReferenceException` for mistyped default values on non-string
  columns in migrations
  ([dotnet/efcore #38399](https://github.com/dotnet/efcore/pull/38399)).
- Fixed compiled model `CreateRelationalModel()` failing when an owned entity
  shares its owner's table
  ([dotnet/efcore #38428](https://github.com/dotnet/efcore/pull/38428)).
- Fixed SQL Server `SIGN()` returning a floating-point value where an integer
  was expected by wrapping the result in `CAST(... AS int)`
  ([dotnet/efcore #38260](https://github.com/dotnet/efcore/pull/38260)).
- Fixed `ALTER COLUMN` being emitted unnecessarily during migrations when a
  computed column's CLR type changes but the SQL expression is unchanged
  ([dotnet/efcore #38252](https://github.com/dotnet/efcore/pull/38252)).
  Thanks [@Clauver](https://github.com/Clauver) for the contribution.

## Community contributors

Thank you contributors! ❤️

- [@ChristopherHaws](https://github.com/dotnet/efcore/pulls?q=is%3Apr+is%3Amerged+author%3AChristopherHaws)
- [@chtdelia](https://github.com/dotnet/efcore/pulls?q=is%3Apr+is%3Amerged+author%3Achtdelia)
- [@Clauver](https://github.com/dotnet/efcore/pulls?q=is%3Apr+is%3Amerged+author%3AClauver)
- [@sebastienros](https://github.com/dotnet/efcore/pulls?q=is%3Apr+is%3Amerged+author%3Asebastienros)
- [@tebeco](https://github.com/dotnet/efcore/pulls?q=is%3Apr+is%3Amerged+author%3Atebeco)
