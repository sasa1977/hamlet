defmodule Hamlet.SchedulerUtilizationTest do
  use ExUnit.Case, async: true
  alias Hamlet.SchedulerUtilization

  describe "average" do
    test "is initially zero" do
      server = start_server()
      assert SchedulerUtilization.average(server.name) == 0.0
    end

    test "periodically takes new sample" do
      server = start_server(initial_sample: [{:normal, 0, 0, 0}, {:cpu, 1, 0, 0}])

      # generates the sample which represents scheduler utilizations of 10% and 30%
      sample(server, [{:normal, 0, 10, 100}, {:cpu, 1, 30, 100}])

      # 0.2 is the average of scheduler utilizations
      assert SchedulerUtilization.average(server.name) == 0.2
    end
  end

  defp start_server(opts \\ []) do
    name = :"#{__MODULE__}#{System.unique_integer([:positive, :monotonic])}"

    initial_sample = Keyword.get(opts, :initial_sample, [])
    sample_storage = start_supervised!({Agent, fn -> initial_sample end})
    sampler = fn -> {:scheduler_wall_time, Agent.get(sample_storage, & &1)} end

    start_supervised!({SchedulerUtilization, name: name, interval: :infinity, sampler: sampler})
    %{name: name, sample_storage: sample_storage}
  end

  defp sample(server, sample) do
    Agent.update(server.sample_storage, fn _ -> sample end)
    send(server.name, :sample)
  end
end
