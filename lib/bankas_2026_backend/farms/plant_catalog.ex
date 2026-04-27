defmodule Bankas2026Backend.Farms.PlantCatalog do
  @moduledoc """
  Hard-coded plant metadata used by the Farms domain.
  """

  @plants %{
    "LETTUCE" => %{
      kind: "LETTUCE",
      growing_time_s: 3_600,
      weight_g: %{5 => 1_000, 4 => 800, 3 => 600, 2 => 400, 1 => 200}
    },
    "TOMATO" => %{
      kind: "TOMATO",
      growing_time_s: 14_400,
      weight_g: %{5 => 5_000, 4 => 4_500, 3 => 3_000, 2 => 1_000, 1 => 800}
    },
    "CARROT" => %{
      kind: "CARROT",
      growing_time_s: 7_200,
      weight_g: %{5 => 3_000, 4 => 2_000, 3 => 1_500, 2 => 900, 1 => 500}
    },
    "PUMPKIN" => %{
      kind: "PUMPKIN",
      growing_time_s: 21_600,
      weight_g: %{5 => 7_000, 4 => 6_000, 3 => 4_000, 2 => 1_000, 1 => 900}
    }
  }

  @spec all() :: [map()]
  def all, do: Map.values(@plants)

  @spec kinds() :: [String.t()]
  def kinds, do: Map.keys(@plants)

  @spec fetch(String.t()) :: {:ok, map()} | :error
  def fetch(kind) when is_binary(kind), do: Map.fetch(@plants, kind)
end
