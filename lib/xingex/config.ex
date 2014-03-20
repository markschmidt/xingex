defmodule XingEx.Config do
  use ExConf.Config

  config :urls, host: "https://api.xing.com",
                request_token_path: "/v1/request_token",
                authorize_path: "/v1/authorize",
                access_token_path: "/v1/access_token"

  config :consumer, key: System.get_env("CONSUMER_KEY"),
                    secret: System.get_env("CONSUMER_SECRET")

end
