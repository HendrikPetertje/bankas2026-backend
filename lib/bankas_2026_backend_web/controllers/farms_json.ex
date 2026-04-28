defmodule Bankas2026BackendWeb.FarmsJSON do
  def plant_info(%{plants: plants}) do
    %{plants: Enum.map(plants, &serialize_plant/1)}
  end

  def me(%{garden: garden}) do
    %{garden: garden}
  end

  defp serialize_plant(plant) do
    %{
      kind: plant.kind,
      growing_time_s: plant.growing_time_s,
      weight_g:
        Map.new(plant.weight_g, fn {stars, grams} -> {Integer.to_string(stars), grams} end)
    }
  end
end
