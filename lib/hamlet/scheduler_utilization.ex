defmodule Hamlet.SchedulerUtilization do
  use GenServer

  def start_link(opts),
    # name is configurable to support testing
    do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))

  def average(name \\ __MODULE__),
    do: GenServer.call(name, :average)

  @impl GenServer
  def init(opts) do
    :erlang.system_flag(:scheduler_wall_time, true)

    interval = Keyword.get(opts, :interval, :timer.seconds(1))
    sampler = Keyword.get(opts, :sampler, &:scheduler.get_sample/0)

    schedule_next_sample(interval)

    {:ok,
     %{
       interval: interval,
       sampler: sampler,
       sample: sampler.(),
       system_info: Keyword.get(opts, :system_info, &:erlang.system_info/1),
       average_utilization: 0.0
     }}
  end

  @impl GenServer
  def handle_call(:average, _from, state),
    do: {:reply, state.average_utilization, state}

  @impl GenServer
  def handle_info(:sample, state) do
    new_sample = state.sampler.()
    schedule_next_sample(state.interval)
    average = average_utilization(state.sample, new_sample, state.system_info)
    {:noreply, %{state | average_utilization: average}}
  end

  defp average_utilization(sample1, sample2, system_info) do
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
      Enum.take(normal_utilizations, system_info.(:schedulers_online)) ++
        Enum.take(dirty_cpu_utilizations, system_info.(:dirty_cpu_schedulers_online))

    Enum.sum(online_utilizations) / length(online_utilizations)
  end

  defp schedule_next_sample(:infinity), do: :ok
  defp schedule_next_sample(interval), do: Process.send_after(self(), :sample, interval)
end
