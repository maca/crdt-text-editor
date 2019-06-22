defmodule MixProject do
  use Mix.Project

  def project do
    [
      app: :codecolab,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {CodeColab, []},
      extra_applications: [:logger, :cowboy]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.5.0"},
      {:phoenix_pubsub, "~> 1.1.2"}
    ]
  end
end
