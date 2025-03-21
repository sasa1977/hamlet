defmodule Hamlet.MixProject do
  use Mix.Project

  def project do
    [
      app: :hamlet,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Hamlet.Application, []}
    ]
  end

  defp deps do
    []
  end
end
