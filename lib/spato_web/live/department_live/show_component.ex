defmodule SpatoWeb.DepartmentLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"department-show-#{@id}"} class="p-4">
      <.header>Lihat Jabatan<:subtitle>Maklumat jabatan.</:subtitle></.header>

      <.list>
        <:item title="Nama Jabatan">{@department.name}</:item>
        <:item title="Kod Jabatan">{@department.code}</:item>
      </.list>
    </div>
    """
  end
end
