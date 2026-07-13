# SDK & Tooling in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new SDK and tooling features:

<!-- toc -->

- [MCP server project template](#mcp-server-project-template)
- [TypeScript Static Web Assets integration](#typescript-static-web-assets-integration)
- [`dotnet test --no-dependencies`](#dotnet-test---no-dependencies)
- [Standard OpenTelemetry OTLP environment variables](#standard-opentelemetry-otlp-environment-variables)
- [`dotnet watch`: hot reload support warning](#dotnet-watch-hot-reload-support-warning)
- [Terminal logger arguments forwarded to MSBuild](#terminal-logger-arguments-forwarded-to-msbuild)
- [Currently running tests in `dotnet test` output](#currently-running-tests-in-dotnet-test-output)
- [`dotnet tool update` version message improvements](#dotnet-tool-update-version-message-improvements)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

SDK updates in .NET 11:

- [What's new in .NET 11 SDK](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-11/sdk)

## MCP server project template

A new `mcpserver` project template is bundled with the .NET 11 SDK. Running `dotnet new mcpserver` creates a minimal MCP (Model Context Protocol) server project — a .NET console app wired up with the `Microsoft.McpServer` SDK, ready to expose tools and resources to MCP clients like GitHub Copilot.

```bash
dotnet new mcpserver -n MyMcpServer
cd MyMcpServer
dotnet run
```

The template produces a working skeleton that registers a single example tool and handles the MCP JSON-RPC protocol over stdio ([dotnet/sdk #54132](https://github.com/dotnet/sdk/pull/54132)).

## TypeScript Static Web Assets integration

The .NET SDK's Static Web Assets pipeline now supports TypeScript source files as a first-class input. When a project includes `.ts` files in the static web assets item group, the build pipeline invokes the TypeScript compiler (`tsc`) and produces `.js` output that is handled through the same fingerprinting, bundling, and publish paths as hand-written JavaScript files.

This allows Razor-based projects and Blazor apps to write TypeScript for client-side logic without a separate `npm build` step or a custom MSBuild target ([dotnet/sdk #52302](https://github.com/dotnet/sdk/pull/52302)).

## `dotnet test --no-dependencies`

`dotnet test` gains a `--no-dependencies` option, analogous to `dotnet build --no-dependencies`. When set, the test runner skips building project dependencies and runs tests against already-built outputs only. This speeds up iterative test runs in repositories where dependencies have not changed ([dotnet/sdk #54435](https://github.com/dotnet/sdk/pull/54435)).

## Standard OpenTelemetry OTLP environment variables

The .NET SDK now respects the standard OpenTelemetry OTLP exporter environment variables (`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_PROTOCOL`, etc.) to enable or configure telemetry exporters. Previously the SDK used its own environment variable conventions; aligning with the OTLP standard makes it easier to connect `.NET` CLI telemetry to existing observability infrastructure without custom configuration ([dotnet/sdk #54386](https://github.com/dotnet/sdk/pull/54386)).

## `dotnet watch`: hot reload support warning

`dotnet watch` now emits a warning when `MetadataUpdaterSupport` is `false` for the target project or runtime. This property is set to `false` on certain configurations (for example, some NativeAOT or trimmed builds) where hot reload cannot function. Previously `dotnet watch` would silently launch but fail to apply hot reload deltas; now it warns up front so you know to rebuild and restart manually ([dotnet/sdk #54264](https://github.com/dotnet/sdk/pull/54264)).

## Terminal logger arguments forwarded to MSBuild

When you run `dotnet test`, terminal logger arguments (e.g., `--logger "console;verbosity=detailed"`) are now forwarded to the underlying MSBuild invocation. Previously these arguments were consumed by the `dotnet test` front-end and not propagated, resulting in MSBuild using its default log output regardless of what was specified ([dotnet/sdk #54310](https://github.com/dotnet/sdk/pull/54310)).

## Currently running tests in `dotnet test` output

The Microsoft Testing Platform (MTP) output mode in `dotnet test` now shows a live list of currently running tests. Instead of only showing pass/fail results as they complete, the output includes a "running" indicator for each test that is in flight — useful for diagnosing hangs and long-running tests in parallel test runs ([dotnet/sdk #49712](https://github.com/dotnet/sdk/pull/49712)).

## `dotnet tool update` version message improvements

`dotnet tool update` now includes the existing installed version in its output when a tool is already up to date or when an update is applied:

```text
Tool 'dotnet-ef' was successfully updated from version '10.0.0' to version '11.0.0-preview.6.xxxxx.x'.
```

Previously the output only mentioned the new version, making it unclear what changed. Dead code related to version messaging was also removed ([dotnet/sdk #54192](https://github.com/dotnet/sdk/pull/54192)).

## Bug fixes

- `dotnet` CLI no longer crashes when `global.json` is present but unreadable ([dotnet/sdk #54433](https://github.com/dotnet/sdk/pull/54433)).
- Fixed `--environment` variables not being applied to the test process when no launch profile is specified ([dotnet/sdk #53306](https://github.com/dotnet/sdk/pull/53306)).
- `launchSettings.json` profile parsing now tolerates JSON comments and trailing commas ([dotnet/sdk #54820](https://github.com/dotnet/sdk/pull/54820)).
- `dotnet tool install`/`update` error messages now include the resolved version when the version in `DotnetToolSettings` is invalid ([dotnet/sdk #54822](https://github.com/dotnet/sdk/pull/54822)).
- Fixed a parallel-build race condition in the `RunnableProjects` DLL resolution ([dotnet/sdk #54380](https://github.com/dotnet/sdk/pull/54380)).
- File-based apps: custom included item types are now handled correctly during project system conversion ([dotnet/sdk #54251](https://github.com/dotnet/sdk/pull/54251)).

## Community contributors

No external community contributors were identified for the SDK in this preview.
