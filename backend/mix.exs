defmodule MixProject do
  use Mix.Project

  def project do
    [
      app: :codecolab,
      version: "0.1.0",
      elixir: "~> 1.11.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: { CodeColab, [] },
      extra_applications: [:logger, :cowboy]
    ]
  end

  def releases do
    [
      editor: [
        include_executables_for: [:unix],
        steps: [&build_frontend/1, :assemble]
      ]
    ]
  end

  def build_frontend(release) do
    static_dir = Path.absname "./priv/static"
    frontend_dir = Path.absname "../frontend"

    { _, 0 } = System.cmd("mkdir", ["-p", static_dir])
    { _, 0 } = System.cmd("elm",
      [ "make",
        "src/Main.elm",
        "--optimize",
        "--output=build/main.prod.js"
      ], cd: frontend_dir)
    { _, 0 } = System.cmd("cp",
      ["-r", "#{frontend_dir}/js", static_dir])
    { _, 0 } = System.cmd("cp",
      [ "-r",
        "#{frontend_dir}/build/main.prod.js",
        "#{static_dir}/js"
      ])

    release
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :cowboy, "~> 2.5.0" },
      { :phoenix_pubsub, "~> 1.1.2" }
    ]
  end
end
