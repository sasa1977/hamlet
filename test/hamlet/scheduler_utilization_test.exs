defmodule Hamlet.SchedulerUtilizationTest do
  use ExUnit.Case, async: true
  alias Hamlet.SchedulerUtilization

  describe "average" do
    test "is initially zero" do
      server = start_server()
      assert SchedulerUtilization.average(server.name) == 0.0
    end

    test "periodically takes new sample" do
      server = start_server()
      sample(server)
      assert SchedulerUtilization.average(name) > 0.0
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
