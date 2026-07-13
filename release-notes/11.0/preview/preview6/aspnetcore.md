# ASP.NET Core in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes many new ASP.NET Core features:

<!-- toc -->

- [Union type support across the stack](#union-type-support-across-the-stack)
- [OpenAPI 3.2 by default](#openapi-32-by-default)
- [Fetch Metadata CSRF protection](#fetch-metadata-csrf-protection)
- [Deferred antiforgery validation via `IAntiforgeryValidationFeature`](#deferred-antiforgery-validation-via-iantiforgeryvalidationfeature)
- [Async validation support in `Microsoft.Extensions.Validation`](#async-validation-support-in-microsoftextensionsvalidation)
- [Blazor: `SupplyParameterFromSession`](#blazor-supplyparameterfromsession)
- [Blazor: WebAssembly out-of-process renderer](#blazor-webassembly-out-of-process-renderer)
- [Blazor: Media components package](#blazor-media-components-package)
- [Blazor: `Virtualize` improvements](#blazor-virtualize-improvements)
- [SignalR: hub method cancellation from client](#signalr-hub-method-cancellation-from-client)
- [SignalR: authentication refresh](#signalr-authentication-refresh)
- [Middleware: defer implicit middleware to after routing](#middleware-defer-implicit-middleware-to-after-routing)
- [`dotnet-user-jwts` file-based app support](#dotnet-user-jwts-file-based-app-support)
- [`WebApplicationFactory.ConfigureHostApplicationBuilder`](#webapplicationfactoryconfigurehostapplicationbuilder)
- [Short circuit attribute](#short-circuit-attribute)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

ASP.NET Core updates in .NET 11:

- [What's new in ASP.NET Core for .NET 11](https://learn.microsoft.com/aspnet/core/release-notes/aspnetcore-11)

## Union type support across the stack

ASP.NET Core now supports C# 14 `union` types as endpoint parameters and return types across Minimal APIs, MVC, Razor Pages, SignalR, and Blazor. This builds on the `System.Text.Json` union serialization support in the runtime.

- **Minimal APIs** — union types are recognized as endpoint parameters (via route, query, or body binding) and as return types. Route Data Formatting and Result Data Generation both handle union cases ([dotnet/aspnetcore #66951](https://github.com/dotnet/aspnetcore/pull/66951)).
- **MVC / Razor Pages** — model binding, action parameters, and action return types all accept union values ([dotnet/aspnetcore #67005](https://github.com/dotnet/aspnetcore/pull/67005)).
- **ApiExplorer / OpenAPI** — endpoints with union parameters or return types produce correct `oneOf` schemas in the OpenAPI document ([dotnet/aspnetcore #67001](https://github.com/dotnet/aspnetcore/pull/67001)).
- **SignalR** — hub method parameters and return types can be union types, and the JavaScript/TypeScript client receives the discriminated value transparently ([dotnet/aspnetcore #67125](https://github.com/dotnet/aspnetcore/pull/67125)).
- **Blazor** — component parameters and render fragments support union values; a bug with prerendering unions that have a `null` active case is also fixed ([dotnet/aspnetcore #67296](https://github.com/dotnet/aspnetcore/pull/67296)).

## OpenAPI 3.2 by default

The default OpenAPI specification version for ASP.NET Core projects is now **3.2** (previously 3.0). OpenAPI 3.2 aligns with the draft of the next OpenAPI release and adds support for the `$vocabulary` keyword, webhook definitions, and JSON Schema draft 2020-12 features. The `Microsoft.OpenApi` package has been updated to 3.6.0 ([dotnet/aspnetcore #67097](https://github.com/dotnet/aspnetcore/pull/67097), [dotnet/aspnetcore #66998](https://github.com/dotnet/aspnetcore/pull/66998)).

OpenAPI generation now also emits additional operation types (like `webhooks`) when the specification version supports them ([dotnet/aspnetcore #67007](https://github.com/dotnet/aspnetcore/pull/67007)).

## Fetch Metadata CSRF protection

ASP.NET Core gains a new CSRF protection algorithm based on [Fetch Metadata headers](https://www.w3.org/TR/fetch-metadata/). The `Sec-Fetch-Site` header (sent automatically by modern browsers) identifies whether a request originated from the same site, same origin, or a cross-site context. The new middleware can enforce a resource isolation policy based on this header, blocking cross-site requests that lack the expected metadata — without requiring an antiforgery token on every endpoint ([dotnet/aspnetcore #66585](https://github.com/dotnet/aspnetcore/pull/66585)).

## Deferred antiforgery validation via `IAntiforgeryValidationFeature`

**Breaking change.** Antiforgery validation is no longer performed eagerly at the middleware layer for all form-consuming endpoints. Instead, the new `IAntiforgeryValidationFeature` on `HttpContext.Features` defers validation until the framework actually reads the form body. This allows endpoints that conditionally read form data (for example, routes that switch on content type) to skip antiforgery validation entirely when it isn't needed, and avoids spurious 400 responses for requests that the endpoint would never have processed anyway ([dotnet/aspnetcore #67082](https://github.com/dotnet/aspnetcore/pull/67082)).

Existing code that reads `HttpContext.Features.Get<IAntiforgeryValidationFeature>()` should continue to work; code that relied on antiforgery being validated before the controller/page action runs may need to be reviewed.

## Async validation support in `Microsoft.Extensions.Validation`

`Microsoft.Extensions.Validation` (the unified validation framework introduced in Preview 5) now supports `IAsyncValidatable` — an interface for validation logic that requires I/O, such as checking a database for duplicate values. Async validators are invoked alongside synchronous validators during model validation in Minimal APIs and MVC, with proper `await` and cancellation support ([dotnet/aspnetcore #66487](https://github.com/dotnet/aspnetcore/pull/66487)).

## Blazor: `SupplyParameterFromSession`

The new `[SupplyParameterFromSession]` attribute for Blazor components binds a component parameter directly to an HTTP session value, analogous to `[SupplyParameterFromQuery]`. A component property decorated with this attribute is automatically populated from the session store on each render, and changes to the property are persisted back. This removes the boilerplate of manually reading and writing session in a component's lifecycle methods ([dotnet/aspnetcore #65184](https://github.com/dotnet/aspnetcore/pull/65184)).

## Blazor: WebAssembly out-of-process renderer

Blazor WebAssembly now supports an **out-of-process renderer**: the Blazor runtime runs in a separate process (or worker thread) from the browser's main thread, and the rendered output is transferred via a shared memory channel. This enables heavier Blazor apps to avoid blocking the UI thread during rendering. The feature is opt-in and requires the new `WebAssemblyOutOfProcessRenderer` configuration ([dotnet/aspnetcore #66442](https://github.com/dotnet/aspnetcore/pull/66442)).

## Blazor: Media components package

Blazor media-related components (audio, video, and related helpers) have been moved to a dedicated `Microsoft.AspNetCore.Components.Media` NuGet package. This reduces the size of the base Blazor runtime package for apps that don't need media playback, and allows the media components to evolve independently ([dotnet/aspnetcore #67130](https://github.com/dotnet/aspnetcore/pull/67130)).

## Blazor: `Virtualize` improvements

The `Virtualize<TItem>` component gains two new capabilities:

- **`InitialIndex`** — sets the starting scroll position to a specific item index when the component first renders, so the list opens at a specific item rather than item 0 ([dotnet/aspnetcore #66753](https://github.com/dotnet/aspnetcore/pull/66753)).
- **`ScrollToIndexAsync`** — programmatically scrolls the virtualized list to a specific item index at any point after rendering, useful for "jump to" navigation ([dotnet/aspnetcore #66753](https://github.com/dotnet/aspnetcore/pull/66753)).
- **CSP compliance** — the `Virtualize` component no longer emits inline `style` attributes that violate strict Content Security Policies; it now uses CSS classes exclusively ([dotnet/aspnetcore #66680](https://github.com/dotnet/aspnetcore/pull/66680)).

## SignalR: hub method cancellation from client

Clients can now cancel in-progress hub method invocations from the .NET client. Pass a `CancellationToken` to `InvokeAsync`/`SendAsync` and cancellation is forwarded to the server-side hub method. The server receives the cancellation through the same `CancellationToken` parameter it already accepts, so no server code changes are required for hubs that already honor cancellation ([dotnet/aspnetcore #64098](https://github.com/dotnet/aspnetcore/pull/64098)).

## SignalR: authentication refresh

SignalR now supports automatic token refresh for long-lived connections. When the access token used to authenticate a SignalR connection expires, the framework calls the configured token provider again and re-authenticates the connection transparently — without dropping it. This is available for both the server and the .NET client ([dotnet/aspnetcore #67400](https://github.com/dotnet/aspnetcore/pull/67400)).

## Middleware: defer implicit middleware to after routing

ASP.NET Core now defers implicit middleware (middleware added by `UseRouting`-adjacent helpers) to run after routing has resolved the endpoint. This ensures that middleware added via convenience extension methods behaves consistently with middleware added explicitly after `UseRouting()`, avoiding subtle ordering bugs where the endpoint was not yet known when the middleware ran ([dotnet/aspnetcore #67307](https://github.com/dotnet/aspnetcore/pull/67307)).

## `dotnet-user-jwts` file-based app support

The `dotnet user-jwts` tool now accepts a `--file` option that points to a file-based app script (`.csx` or a standalone `.cs` file) instead of requiring a project file. This lets developers using the file-based app model manage development JWTs with the same tool they use for project-based apps ([dotnet/aspnetcore #66919](https://github.com/dotnet/aspnetcore/pull/66919), [dotnet/aspnetcore #67010](https://github.com/dotnet/aspnetcore/pull/67010)).

## `WebApplicationFactory.ConfigureHostApplicationBuilder`

`WebApplicationFactory<TEntryPoint>` has a new overridable `ConfigureHostApplicationBuilder` method that runs before the host is built. This allows integration test classes to configure services, options, or settings at the `WebApplicationBuilder` level — not just via `WithWebHostBuilder` — which is important for scenarios where early configuration affects service registration ([dotnet/aspnetcore #66527](https://github.com/dotnet/aspnetcore/pull/66527)).

## Short circuit attribute

The new `[ShortCircuit]` attribute on Minimal API endpoints or endpoint groups marks those endpoints to bypass middleware processing when matched by the router. This replaces the pattern of calling `MapGet(...).ShortCircuit()` on each endpoint individually and is useful for static-file equivalents and health-check endpoints that should skip authentication, logging, and other middleware ([dotnet/aspnetcore #67249](https://github.com/dotnet/aspnetcore/pull/67249)).

## Bug fixes

- Fixed `JsonException` not bubbling through problem-details middleware in Minimal APIs when the request body cannot be deserialized ([dotnet/aspnetcore #66519](https://github.com/dotnet/aspnetcore/pull/66519)).
- Fixed OpenAPI generation incorrectly propagating `JsonSerializerOptions` when multiple documents share the same options instance ([dotnet/aspnetcore #66847](https://github.com/dotnet/aspnetcore/pull/66847)).
- Fixed `DescriptionAttribute` not being picked up for nullable value type properties in OpenAPI schema generation ([dotnet/aspnetcore #65245](https://github.com/dotnet/aspnetcore/pull/65245)).
- Fixed a possible deadlock in `UnixCertificateManager` and `MacOSCertificateManager` ([dotnet/aspnetcore #66727](https://github.com/dotnet/aspnetcore/pull/66727)).
- Fixed output/response caching using the wrong `Vary` header key delimiter for multi-value headers ([dotnet/aspnetcore #66936](https://github.com/dotnet/aspnetcore/pull/66936)).
- Fixed `ValidationsGenerator` emitting a `CS8785` error when `AddValidation` is called from multiple partial-class sites ([dotnet/aspnetcore #66675](https://github.com/dotnet/aspnetcore/pull/66675)).
- Responses for authenticated users are no longer cached by the response caching middleware (backport) ([dotnet/aspnetcore #67110](https://github.com/dotnet/aspnetcore/pull/67110)).
- Fixed Blazor hot reload `ShouldRender` bypass scope to prevent an unbounded re-render loop on component updates ([dotnet/aspnetcore #67372](https://github.com/dotnet/aspnetcore/pull/67372)).
- `ASP0027` is now suppressed for public `partial Program` declarations that already carry attributes ([dotnet/aspnetcore #66875](https://github.com/dotnet/aspnetcore/pull/66875)).
- Cookie authentication now rejects return URLs containing ASCII control characters ([dotnet/aspnetcore #66876](https://github.com/dotnet/aspnetcore/pull/66876)).
- Host filtering middleware now correctly handles leading dots in wildcard patterns ([dotnet/aspnetcore #67265](https://github.com/dotnet/aspnetcore/pull/67265)).
- `QUERY` is now recognized as a known HTTP method in hosting telemetry helpers ([dotnet/aspnetcore #63276](https://github.com/dotnet/aspnetcore/pull/63276)).

## Community contributors

No external community contributors were identified for ASP.NET Core in this preview.
