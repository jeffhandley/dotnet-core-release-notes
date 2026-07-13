# Entity Framework Core in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new Entity Framework Core features:

<!-- toc -->

- [FULL OUTER JOIN support](#full-outer-join-support)
- [SQL Server JSON indexes](#sql-server-json-indexes)
- [Keys and indexes on complex-type properties](#keys-and-indexes-on-complex-type-properties)
- [Cosmos: JSON, composite, include, and exclude indexes](#cosmos-json-composite-include-and-exclude-indexes)
- [Unconstrained foreign key relationships](#unconstrained-foreign-key-relationships)
- [Weakly held detached entries in change tracker](#weakly-held-detached-entries-in-change-tracker)
- [EF1003: Detect unsafe string interpolation in raw SQL APIs](#ef1003-detect-unsafe-string-interpolation-in-raw-sql-apis)
- [SQL Server temporal table period column visibility](#sql-server-temporal-table-period-column-visibility)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

EF Core updates in .NET 11:

- [What's new in EF Core 11](https://learn.microsoft.com/ef/core/what-is-new/ef-core-11.0/whatsnew)

## FULL OUTER JOIN support

EF Core 11 adds LINQ-to-SQL translation for `FULL OUTER JOIN`. Use `FullOuterJoin` (a new LINQ extension method) to join two sequences and include rows from both sides even when there is no match:

```csharp
var results = context.Customers
    .FullOuterJoin(context.Orders,
        customer => customer.Id,
        order => order.CustomerId,
        (customer, order) => new { customer, order });
```

The query is translated to `FULL OUTER JOIN` on providers that support it (SQL Server, PostgreSQL, SQLite). On providers that don't have native `FULL OUTER JOIN`, EF Core emits a `LEFT JOIN UNION ALL RIGHT JOIN` equivalent ([dotnet/efcore #38340](https://github.com/dotnet/efcore/pull/38340)).

## SQL Server JSON indexes

EF Core now supports defining **JSON indexes** on SQL Server JSON columns via the fluent API:

```csharp
modelBuilder.Entity<Order>()
    .HasIndex(e => e.Metadata)
    .IsCreatedOnColumn("$.shipping.zipCode")
    .HasDatabaseName("IX_Orders_Metadata_ZipCode");
```

JSON indexes on SQL Server require SQL Server 2022 or Azure SQL. EF Core generates the correct `CREATE INDEX ... ON (JSON_VALUE(...))` DDL during migrations ([dotnet/efcore #38302](https://github.com/dotnet/efcore/pull/38302)).

## Keys and indexes on complex-type properties

EF Core 11 lifts a longstanding limitation: you can now define primary keys, unique constraints, and indexes that traverse into [complex type](https://learn.microsoft.com/ef/core/what-is-new/ef-core-8.0/whatsnew#complex-types) properties. This is useful when a value-object property contains a field that must be globally unique or is frequently queried:

```csharp
modelBuilder.Entity<Address>()
    .HasIndex(a => a.Location.PostalCode);
```

Previously any attempt to include a complex-type member in an index definition threw at model-build time ([dotnet/efcore #38192](https://github.com/dotnet/efcore/pull/38192)).

## Cosmos: JSON, composite, include, and exclude indexes

The Cosmos DB provider gains support for all four Cosmos index types in the fluent API:

- **JSON indexes** — for JSON properties embedded in the document.
- **Composite indexes** — for queries that order or filter on multiple properties.
- **Include indexes** — for documents that require indexing a subset of properties.
- **Exclude indexes** — to explicitly exclude properties from indexing to save RU cost.

([dotnet/efcore #38360](https://github.com/dotnet/efcore/pull/38360))

## Unconstrained foreign key relationships

EF Core 11 adds support for **unconstrained foreign key relationships** — relationships where the FK column contains a value that may not correspond to any row in the principal table, and no `FOREIGN KEY` constraint is emitted. This is useful for soft-reference patterns, audit tables, and databases that intentionally don't enforce referential integrity at the database level:

```csharp
modelBuilder.Entity<AuditEntry>()
    .HasOne<Order>()
    .WithMany()
    .HasForeignKey(a => a.OrderId)
    .IsConstrained(false);  // no FK constraint in DDL
```

([dotnet/efcore #38361](https://github.com/dotnet/efcore/pull/38361))

## Weakly held detached entries in change tracker

The EF Core change tracker now holds `Detached` state entries **weakly**. When an entity tracked as `Detached` is no longer referenced by application code, the change tracker no longer prevents it from being collected by the GC. This reduces memory pressure in applications that track large numbers of short-lived entities or repeatedly attach and detach objects across many operations ([dotnet/efcore #38387](https://github.com/dotnet/efcore/pull/38387)).

## EF1003: Detect unsafe string interpolation in raw SQL APIs

A new analyzer, **EF1003**, fires when `string.Format` or `string.Concat` is passed to a raw SQL API (`FromSql`, `ExecuteSql`, and friends) **without** going through `FormattableString`. These patterns bypass EF Core's parameterization and introduce a SQL injection risk:

```csharp
// EF1003 fires here — the interpolation is resolved before EF Core sees it:
context.Orders.FromSql($"SELECT * FROM Orders WHERE Id = {id}");   // ✅ safe (FormattableString)
context.Orders.FromSqlRaw(string.Format("SELECT * FROM Orders WHERE Id = {0}", id));  // ❌ EF1003
```

([dotnet/efcore #38208](https://github.com/dotnet/efcore/pull/38208))

## SQL Server temporal table period column visibility

SQL Server temporal tables automatically maintain hidden `ValidFrom`/`ValidTo` system-period columns. EF Core 11 adds an API to configure these columns as **non-hidden** (visible), which is useful when you want to query the period columns directly via LINQ without dropping to raw SQL:

```csharp
modelBuilder.Entity<Employee>()
    .ToTable(tb => tb.IsTemporal(t =>
    {
        t.HasPeriodStart("ValidFrom").HasColumnName("ValidFrom").IsHidden(false);
        t.HasPeriodEnd("ValidTo").HasColumnName("ValidTo").IsHidden(false);
    }));
```

([dotnet/efcore #38225](https://github.com/dotnet/efcore/pull/38225))

## Bug fixes

- Fixed `NullReferenceException` when using `SelectMany` with inline array values ([dotnet/efcore #38286](https://github.com/dotnet/efcore/pull/38286)).
- Fixed `InvalidOperationException` when filtering on a JSON column of an entity mapped to a view ([dotnet/efcore #38321](https://github.com/dotnet/efcore/pull/38321)).
- Fixed `GroupBy.Select` with `EmptyProjectionMember` ([dotnet/efcore #38140](https://github.com/dotnet/efcore/pull/38140)).
- Cosmos: `Any()` at the top level now translates to `LIMIT 1` rather than `EXISTS`, matching the semantics more precisely ([dotnet/efcore #38297](https://github.com/dotnet/efcore/pull/38297)).
- Fixed `SIGN()` translation on SQL Server to emit `CAST(SIGN(...) AS int)` for correct integer result type ([dotnet/efcore #38260](https://github.com/dotnet/efcore/pull/38260)).
- Fixed an `InvalidOperationException` when using the wildcard `*` in `--context` parameter for `ef migrations` commands ([dotnet/efcore #38269](https://github.com/dotnet/efcore/pull/38269)).
- Fixed `funcletization` of evaluatable lambda parameters ([dotnet/efcore #38291](https://github.com/dotnet/efcore/pull/38291)).
- Fixed NativeAOT publish: rebuild RID-specific assembly with generated sources ([dotnet/efcore #38322](https://github.com/dotnet/efcore/pull/38322)).
- Cosmos `ToList()` on a structural collection is no longer treated as a scalar ([dotnet/efcore #38122](https://github.com/dotnet/efcore/pull/38122)).
- Added `UInt128` support in the SQLite value binder ([dotnet/efcore #37492](https://github.com/dotnet/efcore/pull/37492)).
- `List<T>.Exists` now translates to `Queryable.Any` ([dotnet/efcore #38226](https://github.com/dotnet/efcore/pull/38226)).
- `string.Join`/`string.Concat` with ordering now translate correctly on SQLite ([dotnet/efcore #38344](https://github.com/dotnet/efcore/pull/38344)).
- SQL Server `DROP DEFAULT CONSTRAINT` migration query simplified ([dotnet/efcore #38250](https://github.com/dotnet/efcore/pull/38250)).
- SQL Server index with changed facets now uses `CREATE INDEX ... WITH DROP_EXISTING=ON` ([dotnet/efcore #38271](https://github.com/dotnet/efcore/pull/38271)).

## Community contributors

Thank you to the community contributors who contributed to EF Core in this preview:

- [@MaikyOzr](https://github.com/MaikyOzr) — `UInt128` SQLite value binder ([dotnet/efcore #37492](https://github.com/dotnet/efcore/pull/37492))
- [@BrunoSync](https://github.com/BrunoSync) — wildcard `*` support in `--context` parameter ([dotnet/efcore #38269](https://github.com/dotnet/efcore/pull/38269))
