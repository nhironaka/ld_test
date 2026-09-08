namespace DarkStore.Api;

/// <summary>
/// The caller, reduced to the attributes a targeting rule would plausibly
/// want. Built once per request from forwarded auth headers.
/// </summary>
public sealed record Actor(string Key, string? Email, string Plan, string Country)
{
    public static Actor FromRequest(HttpRequest request)
    {
        string Header(string name, string fallback) =>
            request.Headers.TryGetValue(name, out var values) && values.Count > 0
                ? values[0] ?? fallback
                : fallback;

        return new Actor(
            Key: Header("X-User-Key", "anonymous"),
            Email: request.Headers.TryGetValue("X-User-Email", out var email) ? email[0] : null,
            Plan: Header("X-User-Plan", "free"),
            Country: Header("X-User-Country", "US"));
    }
}
