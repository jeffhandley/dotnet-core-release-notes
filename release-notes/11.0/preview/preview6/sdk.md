# SDK & Tooling in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new SDK and tooling features:

<!-- toc -->

- [MCP Server project template](#mcp-server-project-template)
- [File-based apps: reference compiled assemblies with #:include .dll](#file-based-apps-reference-compiled-assemblies-with-include-dll)
- [Test templates improvements](#test-templates-improvements)
- [dotnet watch improvements](#dotnet-watch-improvements)
- [GenAPI improvements](#genapi-improvements)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

SDK & Tooling updates in .NET 11:

- [What's new in .NET 11](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/overview)

## MCP Server project template

The .NET SDK now ships a built-in `mcpserver` project template for creating
Model Context Protocol (MCP) server applications
([dotnet/sdk #54132](https://github.com/dotnet/sdk/pull/54132)).

Create a new MCP server project with:

```bash
dotnet new mcpserver -n MyMcpServer
```

The template scaffolds an MCP server with the basic `Tools`, `Prompts`, and
`Resources` registration patterns and a working entry point ready to connect
to MCP-compatible hosts such as GitHub Copilot, Claude Desktop, and Visual
Studio.

## File-based apps: reference compiled assemblies with #:include .dll

File-based apps (`.cs` scripts run with `dotnet run file.cs`) can now
reference compiled `.dll` assemblies using a `#:include` directive by default
([dotnet/sdk #54396](https://github.com/dotnet/sdk/pull/54396)).

Previously, `#:include` worked for source files and NuGet packages but not for
pre-compiled assemblies. Now you can reference a local `.dll` directly:

```csharp
#!/usr/bin/env dotnet-script
#:include MyLibrary.dll

// MyLibrary types are available here
var helper = new MyLibrary.Helper();
```

This makes it easier to reference shared helpers or vendor libraries without
publishing a NuGet package.

File-based apps also now handle custom MSBuild item types that users have
included in their project-to-script conversion
([dotnet/sdk #54251](https://github.com/dotnet/sdk/pull/54251)).

## Test templates improvements

Several improvements landed for `dotnet new` test project templates.

**xUnit v3 with Microsoft.Testing.Platform by default.** The xUnit template
now has an `XUnitVersion` option that lets you choose between v2 and v3. v3 is
the new default and uses Microsoft.Testing.Platform (MTP) for the test host
([dotnet/sdk #54636](https://github.com/dotnet/sdk/pull/54636)).

```bash
dotnet new xunit                        # xUnit v3 with MTP (default)
dotnet new xunit -o MyTest -xv v2       # xUnit v2 with classic test host
```

**NUnit `--test-runner` option.** NUnit templates now accept a
`--test-runner` option to choose between the classic NUnit runner and MTP
([dotnet/sdk #54638](https://github.com/dotnet/sdk/pull/54638)).

**MSTest `ExplicitProgramFile` option.** The MSTest template now has an
`ExplicitProgramFile` option that controls whether `Program.cs` is generated
as a top-level statements file or an explicit class with a `Main` method
([dotnet/sdk #54596](https://github.com/dotnet/sdk/pull/54596)).

**Bumped package versions.** MSTest, NUnit, and xUnit packages in all
`dotnet new` test templates are updated to their latest stable versions
([dotnet/sdk #54635](https://github.com/dotnet/sdk/pull/54635)).

**`ImplicitUsings` and `Nullable` are conditional on TFM.** These project
properties in test templates are now only set for target frameworks that
support them, so templates targeting `net48` or similar generate correctly
([dotnet/sdk #54594](https://github.com/dotnet/sdk/pull/54594)).

## dotnet watch improvements

`dotnet watch` now emits a warning when `MetadataUpdaterSupport` is `false`,
which is the condition that prevents Hot Reload from applying changes
([dotnet/sdk #54264](https://github.com/dotnet/sdk/pull/54264)).

Previously, Hot Reload silently did nothing in this case, leaving developers
wondering why edits weren't taking effect. The new warning names the
`MetadataUpdaterSupport` property and explains how to enable it, making
the failure mode explicit.

## GenAPI improvements

Several improvements landed for `GenAPI`, the tool that generates reference
assembly API surfaces.

- **`notnull` and `allows ref struct` constraints are preserved.** Generic
  type parameter constraints that were previously dropped from the output
  are now correctly emitted
  ([dotnet/sdk #54455](https://github.com/dotnet/sdk/pull/54455)).
- **Event accessors stay on one line.** The output format for event
  declarations no longer incorrectly wraps `add`/`remove` accessors to a new
  line
  ([dotnet/sdk #54460](https://github.com/dotnet/sdk/pull/54460)).
- **Global namespace types are handled.** Types declared in the global
  namespace no longer cause a `NullReferenceException`
  ([dotnet/sdk #54461](https://github.com/dotnet/sdk/pull/54461)).
- **`IndexerNameAttribute` is emitted for custom-named indexers.** Indexers
  with a non-default compiled name now include the attribute in the generated
  API surface
  ([dotnet/sdk #54526](https://github.com/dotnet/sdk/pull/54526)).
- **Additional API can be explicitly included.** A new flag lets you include
  API that would otherwise be filtered out by default rules
  ([dotnet/sdk #54528](https://github.com/dotnet/sdk/pull/54528)).
- **Explicit interface event implementations are no longer omitted**
  ([dotnet/sdk #54492](https://github.com/dotnet/sdk/pull/54492)).
- **Member spacing is normalized** for consistent output formatting
  ([dotnet/sdk #54458](https://github.com/dotnet/sdk/pull/54458)).

## Bug fixes

- Fixed the CLI parser crashing when `global.json` is present but unreadable
  instead of reporting a clear error
  ([dotnet/sdk #54433](https://github.com/dotnet/sdk/pull/54433)).
- Fixed `dotnet tool exec` / `dnx` failing when a tool exists in
  `dotnet-tools.json` but has not yet been restored
  ([dotnet/sdk #53658](https://github.com/dotnet/sdk/pull/53658)).
- Fixed `dotnet watch` hanging on a device prompt for MAUI workload projects
  ([dotnet/sdk #54392](https://github.com/dotnet/sdk/pull/54392)).

## Community contributors

Thank you contributors! ❤️

- [@baronfel](https://github.com/dotnet/sdk/pulls?q=is%3Apr+is%3Amerged+author%3Abaronfel)
- [@Youssef1313](https://github.com/dotnet/sdk/pulls?q=is%3Apr+is%3Amerged+author%3AYoussef1313)
