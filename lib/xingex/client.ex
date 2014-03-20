defmodule XingEx.Client do
  alias HTTPotion.Response
  alias XingEx.Config

  defrecord RequestToken, token: nil, secret: nil
  defrecord AccessToken, token: nil, secret: nil, user_id: nil

  def get_request_token(callback_url \\ "oob") do
    case fetch_request_token(callback_url) do
      { :ok, body } -> { :ok, body |> parse_request_token_response |> store_token }
      error -> error
    end
  end

  def get_authorize_url(request_token) do
    build_url([:host, :authorize_path]) <> "?oauth_token=" <> request_token.token
  end

  def get_access_token(request_token_str, verifier) do
    case fetch_access_token(request_token_str, verifier) do
      { :ok, body } -> { :ok, body |> parse_access_token_response }
      error -> error
    end
  end

  defp fetch_request_token(callback_url) do
    case HTTPotion.post(build_url([:host, :request_token_path]), request_token_signature(callback_url)) do
      Response[body: body, status_code: status, headers: _headers ]
      when status in 200..299 ->
        { :ok, body }
      Response[body: body, status_code: _status, headers: _headers ] ->
        { :error, body }
    end
  end

  defp fetch_access_token(request_token_str, verifier) do
    RequestToken[token: token, secret: secret] = XingEx.TokenStore.get_token(request_token_str)

    case HTTPotion.post("https://api.xing.com/v1/access_token", access_token_signature(token, secret, verifier)) do
      Response[body: body, status_code: status, headers: _headers ]
      when status in 200..299 ->
        { :ok, body }
      Response[body: body, status_code: _status, headers: _headers ] ->
        { :error, body }
    end
  end

  defp parse_request_token_response(body) do
    dict = parse_url_encoded_response(body)
    RequestToken.new token: dict["oauth_token"], secret: dict["oauth_token_secret"]
  end

  defp parse_access_token_response(body) do
    dict = parse_url_encoded_response(body)
    AccessToken.new token: dict["oauth_token"], secret: dict["oauth_token_secret"], user_id: dict["user_id"]
  end

  defp parse_url_encoded_response(body) do
    body
      |> String.split("&")
      |> HashDict.new fn x -> list_to_tuple(String.split(x, "=")) end
  end

  defp store_token(token) do
    XingEx.TokenStore.save_token(token)
    token
  end

  defp oauth_signature(token \\ "", token_secret \\ "") do
    "oauth_consumer_key=" <> Config.consumer[:key] <>
      "&oauth_token=" <> token <>
      "&oauth_signature_method=PLAINTEXT" <>
      "&oauth_signature=" <> Config.consumer[:secret] <> "%26" <> token_secret <>
      "&oauth_nonce=123" <>
      "&oauth_timestamp=" <> (Timex.Time.now(:secs) |> Float.ceil |> integer_to_binary) <>
      "&oauth_version=1.0"

  end

  defp request_token_signature(callback_url) do
    oauth_signature <>
      "&oauth_callback=" <> URI.encode(callback_url)
  end

  defp access_token_signature(token, token_secret, verifier) do
    oauth_signature(token, token_secret) <>
      "&oauth_verifier=" <> verifier
  end

  def build_url(keys) when is_list(keys) do
    keys |> Enum.map(&Config.urls[&1]) |> Enum.join
  end
  def build_url(key), do: build_url([key])
end
