# ASP.NET Core in .NET 11 Preview 3 - Release Notes

ASP.NET Core updates in .NET 11 Preview 3:

- [What's new in ASP.NET Core in .NET 11](https://learn.microsoft.com/aspnet/core/release-notes/aspnetcore-11.0) documentation

## Blazor

### Virtualize component supports variable-height items

The `Virtualize` component can now render lists where items have different heights. Previously, the component required all items to share a uniform row height; that constraint is lifted in Preview 3. ([dotnet/aspnetcore #64964](https://github.com/dotnet/aspnetcore/pull/64964))

To use variable-height virtualization, supply an `ItemSize` callback instead of a fixed `ItemSize` value:

```razor
<Virtualize Items="items" Context="item">
    <ItemContent>
        <div>@item.Title</div>
        @if (item.HasDescription)
        {
            <p>@item.Description</p>
        }
    </ItemContent>
</Virtualize>
```

The component measures each rendered item and adjusts scroll estimates accordingly. A companion fix ensures the visible viewport does not jump when items above it resize while they remain in the DOM. ([dotnet/aspnetcore #65951](https://github.com/dotnet/aspnetcore/pull/65951))

## Project templates

### Azure SQL with Managed Identity in Individual Auth templates

The Individual Auth project template now includes `Microsoft.Data.SqlClient.Extensions.Azure`, enabling Managed Identity authentication against Azure SQL without any additional configuration when deploying to Azure. ([dotnet/aspnetcore #66179](https://github.com/dotnet/aspnetcore/pull/66179))
