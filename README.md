XingEx
======

Elixir wrapper for the XING API

Before you can start using the client, you need a [XING account](https://www.xing.com) and create an application in the [developer portal](https://dev.xing.com/applications) to have a consumer_key and consumer_secret.


*Note: this is still work in progess and more of an experiment than usable code!*

Usage
-----

Play around with it in an iex session:

```bash
> CONSUMER_KEY=<YOUR_CONSUMER_KEY> CONSUMER_SECRET=<YOUR_SECRET> iex -S mix
Interactive Elixir (0.12.5) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> {:ok, req_token } = XingEx.Client.get_request_token
{:ok,
 XingEx.Client.RequestToken[token: "fbd20fd74981f8515995",
  secret: "9029db916c801cc827fa"]}
iex(2)> XingEx.Client.get_authorize_url(req_token)
"https://api.xing.com/v1/authorize?oauth_token=fbd20fd74981f8515995"
iex(3)> {:ok, token } = XingEx.Client.get_access_token(req_token.token, "5350")
{:ok,
 XingEx.Client.AccessToken[token: "2e1a22c754d111f20c68",
  secret: "9d00eb0f256c4faeb2a9", user_id: "7109635_776f72"]}
iex(4)> {:ok, user} = XingEx.Client.get(token, "/v1/users/me", fields: "id,display_name")
{:ok,
 #HashDict<[{"users",
   [#HashDict<[{"id", "7109635_776f72"}, {"display_name", "Mark Schmidt"}]>]}]>}
```
