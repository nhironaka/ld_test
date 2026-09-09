using DarkStore.Api;

var builder = WebApplication.CreateBuilder(args);

// LaunchDarkly when a key is configured; hardcoded defaults when it is not, so
// the service still starts and serves in environments without a key.
if (string.IsNullOrWhiteSpace(builder.Configuration["LaunchDarkly:SdkKey"]))
{
    builder.Services.AddSingleton<IFeatureFlags, StaticFeatureFlags>();
}
else
{
    builder.Services.AddSingleton<IFeatureFlags, LaunchDarklyFeatureFlags>();
}

var app = builder.Build();

// Build the flag client during startup rather than on the first request that
// needs a flag, so its connect-and-wait is not paid by a customer.
_ = app.Services.GetRequiredService<IFeatureFlags>();

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
