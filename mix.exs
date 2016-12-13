defmodule Foo2b.Mixfile do
  use Mix.Project

  def project do
    [app: :foo2b,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:poison, "~> 2.0"},
    {:benchfella, "~> 0.3.0"}]
  end
end
