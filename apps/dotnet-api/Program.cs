using DarkStore.Api;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<IFeatureFlags, StaticFeatureFlags>();

var app = builder.Build();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapGet("/api/storefront", (HttpRequest request, IFeatureFlags flags) =>
{
    var actor = Actor.FromRequest(request);

    return Results.Ok(new
    {
        banner = flags.BannerCopy(actor),
        checkout = flags.CheckoutRedesign(actor) ? "redesign" : "legacy",
    });
});

app.MapPost("/api/cart/items", (HttpRequest request, AddCartItem body, IFeatureFlags flags) =>
{
    var actor = Actor.FromRequest(request);
    var limit = flags.MaxCartItems(actor);

    if (body.Quantity > limit)
    {
        return Results.UnprocessableEntity(new { error = "cart_limit_exceeded", limit });
    }

    return Results.Created("/api/cart/items", new { quantity = body.Quantity, limit });
});

app.Run();

internal sealed record AddCartItem(int Quantity = 1);
