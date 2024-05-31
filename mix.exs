defmodule HlsPlaylist.MixProject do
  use Mix.Project

  def project do
    [
      app: :hls_playlist,
      version: "0.4.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "Simple HLS playlist - m3u8",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/midarrlabs/hls_playlist"}
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:exile, "~> 0.9.1"}
    ]
  end
end
