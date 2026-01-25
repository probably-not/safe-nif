defmodule SafeNIF.MixProject do
  use Mix.Project

  @version "0.0.0-rc.1"
  @source_url "https://github.com/probably-not/safe-nif"
  @homepage_url @source_url

  def project do
    [
      app: :safe_nif,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_path(Mix.env()),
      deps: deps(),
      name: "SafeNIF",
      description:
        "./README.md"
        |> Path.expand()
        |> File.read!()
        |> String.split("<!-- HEX PACKAGE DESCRIPTION START -->")
        |> Enum.at(1)
        |> String.split("<!-- HEX PACKAGE DESCRIPTION END -->")
        |> List.first()
        |> String.trim(),
      source_url: @source_url,
      homepage_url: @homepage_url,
      package: [
        maintainers: ["Coby Benveniste"],
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url, "Home Page" => @homepage_url},
        files: ["lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"]
      ],
      aliases: aliases(),
      docs: docs(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"},
        plt_core_path: "priv/plts/core.plt",
        plt_add_deps: :app_tree,
        plt_add_apps: [],
        ignore_warnings: ".dialyzer.ignore-warnings.exs"
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      default_env: :dev,
      preferred_envs: [
        ci: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_path(:test), do: ["lib/", "test/support", "bench/"]
  defp elixirc_path(:dev), do: ["lib/", "test/support", "bench/"]
  defp elixirc_path(_), do: ["lib/"]

  def application do
    [
      extra_applications: applications(Mix.env()),
      mod: {SafeNIF.Application, []}
    ]
  end

  defp applications(:dev), do: applications(:all) ++ [:remixed_remix, :runtime_tools]
  defp applications(_all), do: [:logger]

  defp deps do
    [
      ## Testing and Development Dependencies
      {:git_hooks, "~> 0.8.0", only: [:dev], runtime: false},
      {:styler, "~> 1.10", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:remixed_remix, "~> 2.0.2", only: :dev},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_markdown, "~> 0.3", only: :dev}
    ]
  end

  defp aliases do
    []
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "README.md": [title: "README"]
      ],
      groups_for_extras: [],
      skip_undefined_reference_warnings_on: Path.wildcard("**/*.md"),
      main: "readme",
      source_ref: "v#{@version}"
    ]
  end
end
