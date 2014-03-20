defmodule XingEx.Client do
  alias HTTPotion.Response
  alias XingEx.Config

  defrecord RequestToken, token: nil, secret: nil
  defrecord AccessToken, token: nil, secret: nil, user_id: nil

  def get_request_token(callback_url \\ "oob") do
    case HTTPotion.post(url_for(:request_token_path), request_token_signature(callback_url)) do
      Response[body: body, status_code: status, headers: _headers ]
      when status in 200..299 ->
        { :ok, body |> parse_request_token_response |> store_token }
      Response[body: body, status_code: _status, headers: _headers ] ->
        { :error, body }
    end
  end

  def get_authorize_url(request_token) do
    url_for(:authorize_path) |> append_params(oauth_token: request_token.token)
  end

  def get_access_token(request_token_str, verifier) do
    RequestToken[token: token, secret: secret] = XingEx.TokenStore.get_token(request_token_str)

    case HTTPotion.post(url_for(:access_token_path), access_token_signature(token, secret, verifier)) do
      Response[body: body, status_code: status, headers: _headers ]
      when status in 200..299 ->
        { :ok, body |> parse_access_token_response }
      Response[body: body, status_code: _status, headers: _headers ] ->
        { :error, body }
    end
  end

  def get(access_token, path, params \\ []) do
    url = url_for(path) |> append_params(params) |> sign_url(access_token)
    case HTTPotion.get(url) do
      Response[body: body, status_code: status, headers: _headers ]
      when status in 200..299 ->
        { :ok, body |> parse_json_response }
      Response[body: body, status_code: _status, headers: _headers ] ->
        { :error, body }
    end
  end


  defp join_params(params) do
    Keyword.keys(params)
      |> Enum.map(fn(key) -> atom_to_binary(key) <> "=" <> params[key] end)
      |> Enum.join("&")
  end

  defp append_params(url, params) do
    separator = if String.contains?(url, "?"), do: "&", else: "?"
    url <> separator <> join_params(params)
  end

  defp sign_url(url, token) do
    url |> append_params(oauth_params(token.token, token.secret))
  end

  defp parse_json_response(body) do
    { :ok, dict } = body |> JSON.decode
    dict
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

  defp oauth_params(token \\ "", token_secret \\ "") do
    [
      oauth_consumer_key: Config.consumer[:key],
      oauth_token: token,
      oauth_signature_method: "PLAINTEXT",
      oauth_signature: Config.consumer[:secret] <> "%26" <> token_secret,
      oauth_nonce: "123",
      oauth_timestamp: (Timex.Time.now(:secs) |> Float.ceil |> integer_to_binary),
      oauth_version: "1.0"
    ]
  end

  defp request_token_params(callback_url) do
    oauth_params ++ [oauth_callback: URI.encode(callback_url)]
  end

  defp request_token_signature(callback_url) do
    request_token_params(callback_url) |> join_params
  end

  defp access_token_params(token, token_secret, verifier) do
    oauth_params(token, token_secret) ++ [oauth_verifier: verifier]
  end

  defp access_token_signature(token, token_secret, verifier) do
    access_token_params(token, token_secret, verifier) |> join_params
  end

  defp url_for(keys) when is_list(keys) do
    keys
      |> prepend_if_missing(:host)
      |> Enum.map(fn(x) -> if is_atom(x), do: Config.urls[x], else: x end)
      |> Enum.join
  end
  defp url_for(key), do: url_for([key])

  defp prepend_if_missing(list, key) do
    case list do
      [^key|_] -> list
      _        -> [key | list]
    end
  end
end
