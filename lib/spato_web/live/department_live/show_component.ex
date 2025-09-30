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
        <:item title="Pengurus Jabatan">{@department.head_manager}</:item>
        <:item title="Lokasi Jabatan">{@department.location}</:item>
        <:item title="Deskripsi Jabatan">{@department.description}</:item>
      </.list>
    </div>
    """
  end
end
