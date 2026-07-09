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

## Bug fixes

- Fixed `JsonSerializerOptions` not being correctly propagated to all code
  paths during OpenAPI schema generation, causing inconsistent serialization
  behavior
  ([dotnet/aspnetcore #66847](https://github.com/dotnet/aspnetcore/pull/66847)).
- Fixed `DescriptionAttribute` not being respected for nullable value types
  during OpenAPI schema generation
  ([dotnet/aspnetcore #65245](https://github.com/dotnet/aspnetcore/pull/65245)).
  Thanks [@ChrisMcKee](https://github.com/ChrisMcKee) for the contribution.
- Fixed `JsonException` not bubbling correctly through Problem Details middleware
  in Minimal APIs — exceptions thrown during JSON deserialization now produce
  a structured problem details response
  ([dotnet/aspnetcore #66519](https://github.com/dotnet/aspnetcore/pull/66519)).
- Fixed `NullableConverter` missing types in its supported-type allow list,
  causing binding failures for some nullable value types
  ([dotnet/aspnetcore #66625](https://github.com/dotnet/aspnetcore/pull/66625)).
  Thanks [@xtqqczze](https://github.com/xtqqczze) for the contribution.
- Suppressed `ASP0027` for attributed public partial `Program` declarations to
  reduce spurious warnings in file-based app templates
  ([dotnet/aspnetcore #66875](https://github.com/dotnet/aspnetcore/pull/66875)).
- Fixed Identity email wording for notifications sent to recipients who did not
  initiate the action (password reset, email change confirmations)
  ([dotnet/aspnetcore #66747](https://github.com/dotnet/aspnetcore/pull/66747)).
  Thanks [@guilherme-gonzalez](https://github.com/guilherme-gonzalez) for the contribution.
- Added documentation for antiforgery HTTP method limitations and its interaction
  with `HttpMethodOverride`
  ([dotnet/aspnetcore #66772](https://github.com/dotnet/aspnetcore/pull/66772)).
  Thanks [@zzfima](https://github.com/zzfima) for the contribution.
- Fixed cache key separator missing between multiple `Vary` header values in
  `ResponseCaching` and `OutputCaching`
  ([dotnet/aspnetcore #66936](https://github.com/dotnet/aspnetcore/pull/66936)).

## Community contributors

Thank you contributors! ❤️

- [@ChrisMcKee](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3AChrisMcKee)
- [@guilherme-gonzalez](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Aguilherme-gonzalez)
- [@xtqqczze](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Axtqqczze)
- [@zzfima](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Azzfima)
- [@Swapnali911](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3ASwapnali911)
- [@EduardF1](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3AEduardF1)
- [@martincostello](https://github.com/dotnet/aspnetcore/pulls?q=is%3Apr+is%3Amerged+author%3Amartincostello)
