# ASP.NET Core in .NET 11 Preview 6 - Release Notes

.NET 11 Preview 6 includes new ASP.NET Core features and improvements:

<!-- toc -->

- [SupplyParameterFromSession for Blazor](#supplyparameterfromsession-for-blazor)
- [Virtualize: InitialIndex and ScrollToIndexAsync](#virtualize-initialindex-and-scrolltoindexasync)
- [RenderFragment serialization](#renderfragment-serialization)
- [CSRF protection using Fetch Metadata headers](#csrf-protection-using-fetch-metadata-headers)
- [dotnet-user-jwts --file support for file-based apps](#dotnet-user-jwts---file-support-for-file-based-apps)
- [OpenAPI and union types](#openapi-and-union-types)
- [OpenAPI 3.2: additional operations emission](#openapi-32-additional-operations-emission)
- [Blazor WebAssembly Out-of-Process Renderer](#blazor-webassembly-out-of-process-renderer)
- [Async validation in Microsoft.Extensions.Validation](#async-validation-in-microsoftextensionsvalidation)
- [SignalR: cancel hub invocations from the client](#signalr-cancel-hub-invocations-from-the-client)
- [Deferred antiforgery rejection via IAntiforgeryValidationFeature](#deferred-antiforgery-rejection-via-iantiforgeryvalidationfeature)
- [Routing: short-circuit attribute](#routing-short-circuit-attribute)
- [Virtualize component: CSP compliance](#virtualize-component-csp-compliance)
- [Bug fixes](#bug-fixes)
- [Community contributors](#community-contributors)

<!-- tocstop -->

ASP.NET Core updates in .NET 11:

- [What's new in ASP.NET Core for .NET 11](https://learn.microsoft.com/aspnet/core/release-notes/aspnetcore-11)

## SupplyParameterFromSession for Blazor

Blazor components can now supply parameter values from server-side session
state using `[SupplyParameterFromSession]`
([dotnet/aspnetcore #65184](https://github.com/dotnet/aspnetcore/pull/65184)).

Previously, Blazor had `[SupplyParameterFromQuery]` and `[SupplyParameterFromForm]`
to bind parameters from the URL or form fields. The new attribute binds from
`ISessionService`, making it straightforward to propagate user-specific state
across navigations without manually injecting and reading the session service.

```csharp
@page "/preferences"

[SupplyParameterFromSession]
public string? Theme { get; set; }
```

The parameter is populated automatically when the page renders, and you can
write back to the session using the injected `ISessionService`. Session-backed
parameters work in SSR mode and integrate with the existing cascading parameter
infrastructure.

## Virtualize: InitialIndex and ScrollToIndexAsync

The `Virtualize<TItem>` component now supports an `InitialIndex` parameter and
a `ScrollToIndexAsync` API for programmatic scroll control
([dotnet/aspnetcore #66753](https://github.com/dotnet/aspnetcore/pull/66753)).

**`InitialIndex`** — scrolls the list to a specific item when the component
first renders, without requiring a JavaScript call:

```razor
<Virtualize Items="messages" InitialIndex="lastReadIndex">
    <ItemContent>
        <MessageRow Message="context" />
    </ItemContent>
</Virtualize>
```

**`ScrollToIndexAsync`** — lets you programmatically navigate to any item in
the list from C# code:

```csharp
@code {
    VirtualizeHandle<Message>? listRef;

    async Task ScrollToNewMessage()
    {
        await listRef!.ScrollToIndexAsync(latestMessageIndex);
    }
}
```

These APIs complement the `AnchorMode` introduced in Preview 4 and extended in
Preview 5, giving you full control over scroll position in virtualized lists.

## RenderFragment serialization

Blazor now supports serializing `RenderFragment` values across component
boundaries ([dotnet/aspnetcore #66528](https://github.com/dotnet/aspnetcore/pull/66528)).

This enables scenarios where a child component receives a render fragment from
a server-rendered parent, crossing the serialization boundary that exists
between different render modes. Content authored as a `RenderFragment` can
now flow between static SSR and interactive sections of a Blazor Web App
without requiring workarounds.

## CSRF protection using Fetch Metadata headers

ASP.NET Core adds a new cross-site request forgery (CSRF) mitigation based on
[Fetch Metadata](https://www.w3.org/TR/fetch-metadata/) request headers
([dotnet/aspnetcore #66585](https://github.com/dotnet/aspnetcore/pull/66585)).

Modern browsers attach `Sec-Fetch-Site`, `Sec-Fetch-Mode`, and `Sec-Fetch-Dest`
headers to every request, describing where the request originated. The new
`FetchMetadataAntiforgery` middleware reads these headers and rejects
cross-site requests for state-changing operations automatically — without
requiring a CSRF token round-trip.

```csharp
builder.Services.AddFetchMetadataAntiforgery();

var app = builder.Build();

app.UseFetchMetadataAntiforgery();
```

The feature is opt-in for now. It complements (rather than replaces) the
existing token-based antiforgery system and is particularly effective for
SPAs and API endpoints that cannot easily embed CSRF tokens.

## dotnet-user-jwts --file support for file-based apps

`dotnet user-jwts` now accepts a `--file` option that points to a `.cs`
script file rather than a project file
([dotnet/aspnetcore #66919](https://github.com/dotnet/aspnetcore/pull/66919)).

This brings the JWT development tool into parity with the file-based app model
introduced in earlier previews. You can now create and manage development JWTs
for file-based apps without wrapping them in a full project:

```bash
dotnet user-jwts create --file MyApp.cs --name "dev-token"
```

User secrets and the associated JWT store are derived from the file's identity,
matching the convention used by `dotnet user-secrets --file`.

## OpenAPI and union types

The OpenAPI infrastructure now understands C# 14 union types as first-class
endpoint parameter and return types.

**ApiExplorer and OpenAPI schema generation** — Union types used as endpoint
parameters or return types are now represented correctly in the generated
OpenAPI schema. The discriminated union structure is encoded using the OpenAPI
`oneOf` composition keyword so client generators can produce idiomatic types
([dotnet/aspnetcore #67001](https://github.com/dotnet/aspnetcore/pull/67001)).

**Minimal APIs and request-delegate generation** — Union types work as
parameter types and return types in Minimal API endpoints, with the full
binding and response machinery
([dotnet/aspnetcore #66951](https://github.com/dotnet/aspnetcore/pull/66951)).

**MVC and Razor Pages** — Controllers and Razor Pages can accept and return
union types, with model binding and action results handling the union cases
([dotnet/aspnetcore #67005](https://github.com/dotnet/aspnetcore/pull/67005)).

**SignalR hub methods** — Union types are supported as hub method parameters
and return types. Serialization uses the union type's JSON-schema shape, and
strongly typed clients on the JavaScript side receive the discriminated payload
([dotnet/aspnetcore #67125](https://github.com/dotnet/aspnetcore/pull/67125)).

Together these changes make C# union types a seamless first-class citizen
across the entire ASP.NET Core stack.

## OpenAPI 3.2: additional operations emission

The OpenAPI document generator now emits non-standard HTTP operations (such as
`QUERY`) under an `x-oai-additionalOperations` extension in OpenAPI 3.1
documents, and as a direct `query` operation in OpenAPI 3.2 documents
([dotnet/aspnetcore #67007](https://github.com/dotnet/aspnetcore/pull/67007)).

This extends the QUERY support introduced in Preview 4 so that API explorers
and client generators that don't understand custom operations can still
discover and consume these endpoints via the extension field.

## Blazor WebAssembly Out-of-Process Renderer

Blazor now supports an out-of-process WebAssembly renderer — a new render
mode that offloads WebAssembly execution from the web server to the browser
while still keeping the gateway server in control of routing and security
([dotnet/aspnetcore #66442](https://github.com/dotnet/aspnetcore/pull/66442)).

With `InteractiveAuto` or explicit `InteractiveWebAssembly` render mode,
Blazor can download and run component code in the browser. The new
out-of-process path separates the renderer host from the application host,
letting the application gateway (e.g., an Aspire AppHost or a standalone
proxy) coordinate the Blazor circuit without requiring the full .NET runtime
on the server. This reduces server-side memory and CPU pressure for
WebAssembly-heavy workloads while preserving server-side routing, auth, and
pre-rendering.

## Async validation in Microsoft.Extensions.Validation

`Microsoft.Extensions.Validation` now supports async validators
([dotnet/aspnetcore #66487](https://github.com/dotnet/aspnetcore/pull/66487)).

The validation API accepted synchronous validators in earlier previews. The
new `IAsyncValidatableObject` interface and `ValidateAsync` overloads let you
perform I/O-bound validation — such as a database uniqueness check — without
blocking a thread:

```csharp
public class NewUserModel : IAsyncValidatableObject
{
    public string UserName { get; set; } = "";

    public async IAsyncEnumerable<ValidationResult> ValidateAsync(
        ValidationContext context,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var db = context.GetRequiredService<AppDbContext>();
        bool exists = await db.Users
            .AnyAsync(u => u.UserName == UserName, cancellationToken);
        if (exists)
            yield return new ValidationResult(
                "Username is already taken.", [nameof(UserName)]);
    }
}
```

Async validation integrates with Minimal APIs, MVC, and the new parameter-
validation middleware the same way synchronous validation does.

## SignalR: cancel hub invocations from the client

SignalR clients can now cancel regular (non-streaming) hub method invocations
([dotnet/aspnetcore #64098](https://github.com/dotnet/aspnetcore/pull/64098)).

Previously, only streaming hub methods supported a `CancellationToken`. Now
you can pass a token to any hub invocation and the cancellation is propagated
to the server when the token fires:

```csharp
// Client side
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
var result = await hubConnection.InvokeAsync<string>(
    "SlowOperation", args, cts.Token);

// Server side — token is cancelled if the client cancels
public async Task<string> SlowOperation(string args, CancellationToken ct)
{
    await Task.Delay(5000, ct);
    return "Done";
}
```

This lets clients abort expensive server-side operations when they navigate
away or time out, reducing unnecessary work on the server.

## Deferred antiforgery rejection via IAntiforgeryValidationFeature

The antiforgery middleware now defers CSRF rejection to the form consumer
rather than short-circuiting the pipeline on the first invalid token
([dotnet/aspnetcore #67082](https://github.com/dotnet/aspnetcore/pull/67082)).

Previously, `app.UseAntiforgery()` rejected a request immediately if the
CSRF token was missing or invalid, before any endpoint ran. This made it
impossible to handle the failure gracefully in a minimal API or controller
that might want to return a custom problem-details response or fall back to a
different auth path.

The new behavior stores the validation result in `IAntiforgeryValidationFeature`
on the `HttpContext` and defers the rejection decision to the handler. The
endpoint can inspect `feature.IsValid` and decide how to respond. The existing
opt-in `[ValidateAntiForgeryToken]` and `RequireAntiforgeryToken()` behaviour
is unchanged; this change only affects the default middleware short-circuit.

> **Note:** This is a breaking change if you relied on the middleware rejecting
> before the endpoint executed. Update any code that expected a 400 response
> before the endpoint body ran.

## Routing: short-circuit attribute

Endpoints can now opt out of the full middleware pipeline by applying
`[ShortCircuit]` (or calling `.ShortCircuit()` on a route group/endpoint)
([dotnet/aspnetcore #67249](https://github.com/dotnet/aspnetcore/pull/67249)).

Short-circuited endpoints skip all middleware registered after `UseRouting`,
including authentication, authorization, CORS, antiforgery, and output
caching. This is useful for health-check endpoints, metrics scrape targets,
and other internal probes that must respond quickly and do not need the full
request processing stack:

```csharp
app.MapGet("/healthz", () => Results.Ok())
   .ShortCircuit();

// Or using the attribute:
[ShortCircuit]
[ApiController]
public class HealthController : ControllerBase
{
    [HttpGet("/healthz")]
    public IActionResult Check() => Ok();
}
```

## Virtualize component: CSP compliance

The `Virtualize<TItem>` component no longer uses inline styles, making it
compatible with strict Content Security Policy (CSP) configurations that
disallow `style-src 'unsafe-inline'`
([dotnet/aspnetcore #66680](https://github.com/dotnet/aspnetcore/pull/66680)).

Previously, `Virtualize` injected an inline `style` attribute on the
spacer elements it uses to simulate scroll height. This blocked CSP deployments
that set a strict `style-src` policy. The component now uses CSS classes
instead, so no CSP exception is needed.

## Bug fixes

- Fixed duplicate XML documentation IDs being generated for generic properties
  and references in OpenAPI schema output
  ([dotnet/aspnetcore #64404](https://github.com/dotnet/aspnetcore/pull/64404)).
- Fixed `If-Match` and `If-None-Match` header parsing having O(n²) complexity
  for large numbers of ETags; now O(n)
  ([dotnet/aspnetcore #66796](https://github.com/dotnet/aspnetcore/pull/66796)).
- Fixed trailing-comma handling in chunked transfer encoding
  ([dotnet/aspnetcore #67006](https://github.com/dotnet/aspnetcore/pull/67006)).
- Fixed `TempData` and `[SupplyParameterFromSession]` not being persisted
  correctly during streaming SSR
  ([dotnet/aspnetcore #66832](https://github.com/dotnet/aspnetcore/pull/66832)).
- Fixed cookie authentication return URLs being accepted with ASCII control
  characters, which could be exploited for open-redirect attacks
  ([dotnet/aspnetcore #66876](https://github.com/dotnet/aspnetcore/pull/66876)).
- Fixed `RouteHandlerAnalyzer` crashing when a generic type parameter is used
  as a handler parameter type
  ([dotnet/aspnetcore #63641](https://github.com/dotnet/aspnetcore/pull/63641)).
- Fixed `HttpSysException` not including `HttpInitialize` status details for
  kernel-mode HTTP.sys initialization errors
  ([dotnet/aspnetcore #66859](https://github.com/dotnet/aspnetcore/pull/66859)).
- Fixed OpenAPI registration not resolving document names on request when
  multiple documents are registered
  ([dotnet/aspnetcore #66692](https://github.com/dotnet/aspnetcore/pull/66692)).
- Added CRLF/LF observability improvements for HTTP/1.x requests; malformed
  line terminators now produce a structured diagnostic instead of silent drops
  ([dotnet/aspnetcore #66807](https://github.com/dotnet/aspnetcore/pull/66807)).
- Fixed host filtering middleware not matching a leading dot when a wildcard
  host entry is used (e.g., `.example.com`)
  ([dotnet/aspnetcore #67265](https://github.com/dotnet/aspnetcore/pull/67265)).

## Community contributors

Thank you contributors! ❤️

- [@ChrisMcKee](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3AChrisMcKee)
- [@guilherme-gonzalez](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Aguilherme-gonzalez)
- [@xtqqczze](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Axtqqczze)
- [@zzfima](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Azzfima)
- [@Swapnali911](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3ASwapnali911)
- [@EduardF1](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3AEduardF1)
- [@martincostello](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Amartincostello)
