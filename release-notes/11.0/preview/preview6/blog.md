# .NET 11 Preview 6

.NET 11 Preview 6 brings significant language and framework advances, with the headline being broad **union type support across the stack**: C# 14 extension indexers and `unsafe` fields continue to mature, `System.Text.Json` gains native union serialization, and ASP.NET Core wires up union types in Minimal APIs, MVC, SignalR, and Blazor. EF Core adds `FULL OUTER JOIN` and SQL Server JSON indexes. The SDK gains a new MCP server project template.

## Highlights by component

- **[C#](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-csharp/release-notes/11.0/preview/preview6/csharp.md)** — Extension indexers reach feature-completeness; `union` types, `unsafe` fields, and labeled `break`/`continue` continue to land. New `RegisterPreCompilationSourceOutput` API for incremental generators.
  - [Extension indexers](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-csharp/release-notes/11.0/preview/preview6/csharp.md#extension-indexers)
  - [Union types](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-csharp/release-notes/11.0/preview/preview6/csharp.md#union-types-continued-progress)

- **[ASP.NET Core](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-aspnetcore/release-notes/11.0/preview/preview6/aspnetcore.md)** — Union types work across the full web stack; OpenAPI 3.2 is now the default; Fetch Metadata CSRF protection; async validation; SignalR auth refresh; Blazor `SupplyParameterFromSession` and out-of-process WASM renderer.
  - [Union type support across the stack](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-aspnetcore/release-notes/11.0/preview/preview6/aspnetcore.md#union-type-support-across-the-stack)
  - [OpenAPI 3.2 by default](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-aspnetcore/release-notes/11.0/preview/preview6/aspnetcore.md#openapi-32-by-default)
  - [Fetch Metadata CSRF protection](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-aspnetcore/release-notes/11.0/preview/preview6/aspnetcore.md#fetch-metadata-csrf-protection)

- **[EF Core](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-efcore/release-notes/11.0/preview/preview6/efcore.md)** — `FULL OUTER JOIN` support; SQL Server JSON indexes; keys and indexes on complex-type properties; weakly held detached change tracker entries; new EF1003 raw-SQL safety analyzer.
  - [FULL OUTER JOIN support](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-efcore/release-notes/11.0/preview/preview6/efcore.md#full-outer-join-support)
  - [SQL Server JSON indexes](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-efcore/release-notes/11.0/preview/preview6/efcore.md#sql-server-json-indexes)

- **[Runtime](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-runtime/release-notes/11.0/preview/preview6/runtime.md)** — `System.Text.Json` union serialization; ARM64 PAC-RET hardware stack protection; `Math.BigMul` x64 improvement; linker dead-code elimination on Unix.
  - [System.Text.Json union support](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-runtime/release-notes/11.0/preview/preview6/runtime.md#systemtextjson-union-support)

- **[SDK & Tooling](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-sdk/release-notes/11.0/preview/preview6/sdk.md)** — New `mcpserver` project template; TypeScript Static Web Assets integration; `dotnet test --no-dependencies`.
  - [MCP server project template](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-sdk/release-notes/11.0/preview/preview6/sdk.md#mcp-server-project-template)
  - [TypeScript Static Web Assets integration](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-sdk/release-notes/11.0/preview/preview6/sdk.md#typescript-static-web-assets-integration)

- **[Libraries](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-libraries/release-notes/11.0/preview/preview6/libraries.md)** — Configurable environment variable name transformation; corrected keyed-service probing; performance improvements.

- **[F#](https://github.com/dotnet/dotnet-core-release-notes/blob/release-notes/dotnet-11-preview-6-features-fsharp/release-notes/11.0/preview/preview6/fsharp.md)** — `InlineIfLambda` for `Array.init`; reworked `for`-loop debugger stepping; new compiler warnings.

## Get started

Download [.NET 11 Preview 6](https://dotnet.microsoft.com/download/dotnet/11.0) and share your feedback on
[GitHub](https://github.com/dotnet/core/issues/new?template=bug_report.yml).

## Give feedback

Your input shapes .NET releases. File issues and suggestions on the component repositories:

- [dotnet/runtime](https://github.com/dotnet/runtime/issues/new/choose)
- [dotnet/aspnetcore](https://github.com/dotnet/aspnetcore/issues/new/choose)
- [dotnet/roslyn](https://github.com/dotnet/roslyn/issues/new/choose)
- [dotnet/efcore](https://github.com/dotnet/efcore/issues/new/choose)
- [dotnet/sdk](https://github.com/dotnet/sdk/issues/new/choose)
- [dotnet/fsharp](https://github.com/dotnet/fsharp/issues/new/choose)
