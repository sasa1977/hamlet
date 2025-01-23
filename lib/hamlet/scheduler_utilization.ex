defmodule Hamlet.SchedulerUtilization do
  use GenServer

  def start_link(arg),
    do: GenServer.start_link(__MODULE__, arg)

  @impl GenServer
  def init(_arg) do
    :erlang.system_flag(:scheduler_wall_time, true)
    schedule_next_sample()
    {:ok, sample: :scheduler.get_sample()}
  end

  @impl GenServer
  def handle_info(:sample, state) do
    new_sample = :scheduler.get_sample()
    schedule_next_sample()
    {:noreply, %{state | sample: new_sample}}
  end

  defp schedule_next_sample,
    do: Process.send_after(self(), :sample, :timer.seconds(1))
end
