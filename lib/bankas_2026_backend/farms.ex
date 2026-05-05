defmodule Bankas2026Backend.Farms do
  @moduledoc """
  Farms domain persistence and game logic.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Bankas2026Backend.Farms.Garden
  alias Bankas2026Backend.Farms.GardenPlot
  alias Bankas2026Backend.Farms.PlantCatalog
  alias Bankas2026Backend.Repo

  @type farm_response :: %{garden: map()}

  @spec create_farm(Ecto.UUID.t()) :: {:ok, farm_response()} | {:error, term()}
  def create_farm(user_id) when is_binary(user_id) do
    multi =
      Multi.new()
      |> Multi.insert(
        :garden,
        Garden.create_changeset(%Garden{}, %{user_id: user_id, produced_g: 0})
      )
      |> Multi.run(:plots, fn repo, %{garden: garden} -> create_initial_plots(repo, garden) end)

    multi
    |> Repo.transaction()
    |> case do
      {:ok, _result} -> get_farm_by_user_id(user_id)
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  @spec get_farm_by_user_id(Ecto.UUID.t()) :: {:ok, farm_response()} | {:error, :not_found}
  def get_farm_by_user_id(user_id) when is_binary(user_id) do
    case load_garden(user_id) do
      nil -> {:error, :not_found}
      garden -> {:ok, %{garden: serialize_garden(garden)}}
    end
  end

  @spec clean_plot(Ecto.UUID.t(), integer()) :: {:ok, farm_response()} | {:error, term()}
  def clean_plot(user_id, plot_number) do
    with_plot_action(user_id, plot_number, true, fn plot, now ->
      case plot.state do
        "BARREN" -> {:ok, %{state: "CLEANED", last_weeds_removed_at: now}}
        "CLEANED" -> {:ok, %{last_weeds_removed_at: now}}
        "SEEDED" -> {:ok, %{last_weeds_removed_at: now}}
        _ -> {:error, :invalid_plot_state}
      end
    end)
  end

  @spec seed_plot(Ecto.UUID.t(), integer(), String.t()) ::
          {:ok, farm_response()} | {:error, term()}
  def seed_plot(user_id, plot_number, plant_kind)
      when is_binary(user_id) and is_integer(plot_number) and is_binary(plant_kind) do
    now = current_time()

    with {:ok, _plant} <- fetch_plant_result(plant_kind),
         {:ok, %{garden: garden, plot: plot}} <- fetch_garden_and_plot(user_id, plot_number),
         :ok <- validate_seed(plot, now) do
      plot
      |> GardenPlot.action_changeset(%{
        state: "SEEDED",
        plant_kind: plant_kind,
        planted_at: now,
        water_stars: 5,
        weed_stars: 5,
        last_penalty_at: nil
      })
      |> Repo.update()
      |> case do
        {:ok, _plot} -> get_farm_by_user_id(garden.user_id)
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  def seed_plot(_user_id, _plot_number, _plant_kind), do: {:error, :invalid_input}

  @spec water_plot(Ecto.UUID.t(), integer()) :: {:ok, farm_response()} | {:error, term()}
  def water_plot(user_id, plot_number) do
    with_plot_action(user_id, plot_number, true, fn _plot, now ->
      {:ok, %{last_watered_at: now}}
    end)
  end

  @spec harvest_plot(Ecto.UUID.t(), integer()) :: {:ok, farm_response()} | {:error, term()}
  def harvest_plot(user_id, plot_number) when is_binary(user_id) and is_integer(plot_number) do
    now = current_time()

    with {:ok, %{garden: garden, plot: plot}} <- fetch_garden_and_plot(user_id, plot_number),
         penalty_attrs <- pre_action_penalty_attrs(plot, now),
         penalized_plot = struct(plot, penalty_attrs),
         :ok <- validate_harvest(penalized_plot, now),
         {:ok, plant} <- fetch_plant_result(penalized_plot.plant_kind) do
      final_stars = min(penalized_plot.water_stars, penalized_plot.weed_stars)
      produced_g = plant.weight_g[final_stars]

      Multi.new()
      |> Multi.update(
        :garden,
        Garden.produced_changeset(garden, %{produced_g: garden.produced_g + produced_g})
      )
      |> Multi.update(
        :plot,
        GardenPlot.action_changeset(
          plot,
          Map.merge(penalty_attrs, %{
            state: "BARREN",
            plant_kind: nil,
            planted_at: nil,
            water_stars: nil,
            weed_stars: nil,
            last_penalty_at: nil
          })
        )
      )
      |> Repo.transaction()
      |> case do
        {:ok, _result} -> get_farm_by_user_id(user_id)
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end
  end

  def harvest_plot(_user_id, _plot_number), do: {:error, :invalid_plot_number}

  defp with_plot_action(user_id, plot_number, apply_penalties?, action_fun)
       when is_binary(user_id) and is_integer(plot_number) and plot_number >= 1 and
              plot_number <= 9 do
    now = current_time()

    with {:ok, %{garden: garden, plot: plot}} <- fetch_garden_and_plot(user_id, plot_number),
         {:ok, action_attrs} <- action_fun.(plot, now) do
      penalty_attrs = if apply_penalties?, do: pre_action_penalty_attrs(plot, now), else: %{}

      plot
      |> GardenPlot.action_changeset(Map.merge(penalty_attrs, action_attrs))
      |> Repo.update()
      |> case do
        {:ok, _plot} -> get_farm_by_user_id(garden.user_id)
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  defp with_plot_action(_user_id, _plot_number, _apply_penalties?, _action_fun),
    do: {:error, :invalid_plot_number}

  defp create_initial_plots(repo, garden) do
    now = current_time()

    Enum.reduce_while(1..9, {:ok, []}, fn number, {:ok, plots} ->
      attrs = %{
        garden_id: garden.id,
        number: number,
        state: "BARREN",
        last_weeds_removed_at: now,
        inserted_at: now,
        updated_at: now
      }

      case repo.insert(GardenPlot.create_changeset(%GardenPlot{}, attrs)) do
        {:ok, plot} -> {:cont, {:ok, [plot | plots]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp load_garden(user_id) do
    plot_query = from plot in GardenPlot, order_by: [asc: plot.number]

    from(garden in Garden,
      where: garden.user_id == ^user_id,
      preload: [:user, plots: ^plot_query]
    )
    |> Repo.one()
  end

  defp fetch_garden_and_plot(user_id, plot_number)
       when is_integer(plot_number) and plot_number >= 1 and plot_number <= 9 do
    case load_garden(user_id) do
      nil ->
        {:error, :not_found}

      garden ->
        case Enum.find(garden.plots, &(&1.number == plot_number)) do
          nil -> {:error, :plot_not_found}
          plot -> {:ok, %{garden: garden, plot: plot}}
        end
    end
  end

  defp fetch_garden_and_plot(_user_id, _plot_number), do: {:error, :invalid_plot_number}

  defp serialize_garden(garden) do
    %{
      user_name: garden.user.username,
      produced_g: garden.produced_g,
      plots: Enum.map(garden.plots, &serialize_plot/1)
    }
  end

  defp serialize_plot(plot) do
    %{
      number: plot.number,
      state: plot.state,
      plant_kind: plot.plant_kind,
      planted_at: plot.planted_at,
      last_watered_at: plot.last_watered_at,
      last_weeds_removed_at: plot.last_weeds_removed_at,
      water_stars: plot.water_stars,
      weed_stars: plot.weed_stars
    }
  end

  defp validate_seed(%GardenPlot{state: "CLEANED", last_watered_at: last_watered_at}, now) do
    if last_watered_at && DateTime.diff(now, last_watered_at, :second) <= 1_800 do
      :ok
    else
      {:error, :watering_required}
    end
  end

  defp validate_seed(_plot, _now), do: {:error, :invalid_plot_state}

  defp validate_harvest(
         %GardenPlot{state: "SEEDED", planted_at: planted_at, plant_kind: plant_kind},
         now
       ) do
    with {:ok, plant} <- fetch_plant_result(plant_kind),
         true <- DateTime.diff(now, planted_at, :second) >= plant.growing_time_s do
      :ok
    else
      false -> {:error, :not_ready_for_harvest}
      :error -> {:error, :invalid_plant_kind}
    end
  end

  defp validate_harvest(_plot, _now), do: {:error, :invalid_plot_state}

  defp pre_action_penalty_attrs(%GardenPlot{state: state}, _now) when state != "SEEDED", do: %{}

  defp pre_action_penalty_attrs(%GardenPlot{last_penalty_at: last_penalty_at} = plot, now) do
    if last_penalty_at && DateTime.diff(now, last_penalty_at, :second) < 1_800 do
      %{}
    else
      maybe_apply_penalties(plot, now)
    end
  end

  defp maybe_apply_penalties(plot, now) do
    with {:ok, plant} <- fetch_plant_result(plot.plant_kind) do
      water_threshold_one = max(round(plant.growing_time_s * 0.3), 3_600)
      water_threshold_two = max(round(plant.growing_time_s * 0.6), 7_200)
      water_age = age_in_seconds(now, plot.last_watered_at)
      weed_age = age_in_seconds(now, plot.last_weeds_removed_at)

      water_stars =
        cond do
          water_age > water_threshold_two -> 1
          water_age > water_threshold_one -> max(plot.water_stars - 1, 1)
          true -> plot.water_stars
        end

      weed_stars =
        if weed_age > 3_600 do
          max(plot.weed_stars - 1, 1)
        else
          plot.weed_stars
        end

      if water_stars != plot.water_stars or weed_stars != plot.weed_stars do
        %{water_stars: water_stars, weed_stars: weed_stars, last_penalty_at: now}
      else
        %{}
      end
    else
      {:error, _reason} -> %{}
    end
  end

  defp age_in_seconds(_now, nil), do: :infinity
  defp age_in_seconds(now, datetime), do: DateTime.diff(now, datetime, :second)

  defp fetch_plant(kind) when is_binary(kind), do: PlantCatalog.fetch(kind)
  defp fetch_plant(_kind), do: {:error, :invalid_plant_kind}

  defp fetch_plant_result(kind) do
    case fetch_plant(kind) do
      {:ok, plant} -> {:ok, plant}
      :error -> {:error, :invalid_plant_kind}
      {:error, _reason} = error -> error
    end
  end

  defp current_time do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end
end
