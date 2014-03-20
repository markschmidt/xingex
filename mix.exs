defmodule Xingex.Mixfile do
  use Mix.Project

  def project do
    [ app: :xingex,
      version: "0.0.1",
      elixir: "~> 0.12.5",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [
      applications: [:httpotion],
      mod: { Xingex, [] }
    ]
  end

  defp deps do
    [
      { :httpotion, "~> 0.2", github: "myfreeweb/httpotion" },
      { :timex,               github: "bitwalker/timex" },
      { :json,                github: "cblage/elixir-json" },
      { :ex_conf,              github: "phoenixframework/ex_conf" }
    ]
  end
end
