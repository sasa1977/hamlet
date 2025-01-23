defmodule Hamlet.SchedulerUtilization do
  use GenServer

  def start_link(arg),
    do: GenServer.start_link(__MODULE__, arg)

  @impl GenServer
  def init(_arg) do
    :erlang.system_flag(:scheduler_wall_time, true)
    schedule_next_sample()
    {:ok, %{sample: :scheduler.get_sample(), average_utilization: 0.0}}
  end

  @impl GenServer
  def handle_info(:sample, state) do
    new_sample = :scheduler.get_sample()
    schedule_next_sample()
    {:noreply, %{state | average_utilization: average_utilization(state.sample, new_sample)}}
  end

  defp average_utilization(sample1, sample2) do
    utilizations = :scheduler.utilization(sample1, sample2)

    # The result of `:scheduler.utilization/2` contains the average of all schedulers (in the tuple
    # tagged with `:total`). However, this is the average of all schedulers, even if some of them
    # are offline (which can e.g. happen when there's a CPU quota in place). So instead, we're
    # computing our own average utilization of the online schedulers only.

    normal_utilizations =
      for {:normal, _id, utilization, _formatted} <- utilizations,
          do: utilization

    dirty_cpu_utilizations =
      for {:cpu, _id, utilization, _formatted} <- utilizations,
          do: utilization

    online_utilizations =
      Enum.take(normal_utilizations, :erlang.system_info(:schedulers_online)) ++
        Enum.take(dirty_cpu_utilizations, :erlang.system_info(:dirty_cpu_schedulers_online))

    Enum.sum(online_utilizations) / length(online_utilizations)
  end

  defp schedule_next_sample,
    do: Process.send_after(self(), :sample, :timer.seconds(1))
end
