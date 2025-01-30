defmodule Hamlet.SchedulerUtilizationTest do
  use ExUnit.Case, async: true
  alias Hamlet.SchedulerUtilization

  describe "average" do
    test "is initially zero" do
      name = start_server()
      assert SchedulerUtilization.average(name) == 0.0
    end

    test "periodically takes new sample" do
      name = start_server()
      sample(name)
      assert SchedulerUtilization.average(name) > 0.0
    end
  end

  defp start_server do
    name = :"#{__MODULE__}#{System.unique_integer([:positive, :monotonic])}"
    start_supervised!({SchedulerUtilization, name: name, interval: :infinity})
    name
  end

  defp sample(name), do: send(name, :sample)
end
