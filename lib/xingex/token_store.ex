defmodule XingEx.TokenStore do
  use GenServer.Behaviour

  #####
  # External API

  def start_link(token_dict \\ HashDict.new) do
    :gen_server.start_link({:local, :token_store}, __MODULE__, token_dict, [])
  end

  def get_token(token_str) do
    :gen_server.call :token_store, { :get_token, token_str }
  end

  def save_token(request_token) do
    :gen_server.cast :token_store, { :save_token, request_token }
  end


  #####
  # GenServer implementation

  def init(token_dict) do
    { :ok, token_dict }
  end

  def handle_call({:get_token, token_str}, _from, token_dict) do
    { value, dict } = HashDict.pop(token_dict, token_str)
    { :reply, value, dict }
  end

  def handle_cast({:save_token, token}, token_dict) do
    # TODO: make sure to truncate the dict to a certain size
    { :noreply, HashDict.put(token_dict, token.token, token) }
  end

  def format_status(_reason, [ _pdict, state ]) do
    [data: [{'State', "Stored #{inspect HashDict.size(state)} values, knowing the following tokens: #{inspect Enum.map(HashDict.values(state), fn(x) -> x.token end)}"}]]
  end

end
