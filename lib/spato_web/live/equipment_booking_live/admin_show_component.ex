defmodule SpatoWeb.EquipmentBookingLive.AdminShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"booking-show-#{@id}"}>
     <.header>
        Equipment booking {@equipment_booking.id}
        <:subtitle>This is a equipment_booking record from your database.</:subtitle>
      </.header>

      <.list>
        <:item title="Quantity">{@equipment_booking.quantity}</:item>
        <:item title="Location">{@equipment_booking.location}</:item>
        <:item title="Usage date">{@equipment_booking.usage_date}</:item>
        <:item title="Return date">{@equipment_booking.return_date}</:item>
        <:item title="Usage time">{@equipment_booking.usage_time}</:item>
        <:item title="Return time">{@equipment_booking.return_time}</:item>
        <:item title="Additional notes">{@equipment_booking.additional_notes}</:item>
        <:item title="Condition before">{@equipment_booking.condition_before}</:item>
        <:item title="Condition after">{@equipment_booking.condition_after}</:item>
        <:item title="Status">{@equipment_booking.status}</:item>
      </.list>
    </div>
    """
  end

end
