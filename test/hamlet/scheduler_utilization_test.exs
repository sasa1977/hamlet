defmodule Hamlet.SchedulerUtilizationTest do
  use ExUnit.Case, async: true
  alias Hamlet.SchedulerUtilization

  describe "average" do
    test "is initially zero" do
      server = start_server()
      assert SchedulerUtilization.average(server.name) == 0.0
    end

    test "periodically takes new sample" do
      {sample1, sample2} = samples(normal: 10, cpu: 30)
      server = start_server(initial_sample: sample1)

      sample(server, sample2)

      # 0.2 is the average of scheduler utilizations (10% and 30%)
      assert SchedulerUtilization.average(server.name) == 0.2
    end

    test "considers only online schedulers" do
      {sample1, sample2} = samples(normal: 10, normal: 20, cpu: 30, cpu: 40)

      server =
        start_server(
          initial_sample: sample1,
          schedulers_online: 1,
          dirty_cpu_schedulers_online: 1
        )

      sample(server, sample2)

      # 0.2 is the average of online scheduler utilizations
      assert SchedulerUtilization.average(server.name) == 0.2
    end

    test "works on the registered server" do
      send(SchedulerUtilization, :sample)
      average = SchedulerUtilization.average()
      assert average >= 0.0 and average <= 1.0
    end
  end

  defp start_server(opts \\ []) do
    name = :"#{__MODULE__}#{System.unique_integer([:positive, :monotonic])}"

    initial_sample = Keyword.get(opts, :initial_sample, [])
    sample_storage = start_supervised!({Agent, fn -> initial_sample end})
    sampler = fn -> {:scheduler_wall_time, Agent.get(sample_storage, & &1)} end

    start_supervised!(
      {SchedulerUtilization,
       name: name,
       interval: :infinity,
       sampler: sampler,
       system_info: &Keyword.get(opts, &1, :erlang.system_info(&1))}
    )

    %{name: name, sample_storage: sample_storage}
  end

  defp sample(server, sample) do
    Agent.update(server.sample_storage, fn _ -> sample end)
    send(server.name, :sample)
  end

  # Given the list of expected utilizations, generate the two samples, which,
  # when passed to `:scheduler.utilization/2` will result in the desired
  # utilizations.
  @spec samples([{:normal | :cpu, utilization_percentage :: non_neg_integer()}]) ::
          {sample1 :: list(), sample2: list()}
  defp samples(schedulers) do
    schedulers
    |> Enum.with_index(1)
    |> Enum.map(fn {{type, utilization}, id} ->
      {
        {type, id, 0, 0},
        {type, id, utilization, 100}
      }
    end)
    |> Enum.unzip()
  end
end
