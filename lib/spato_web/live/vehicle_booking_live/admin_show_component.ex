defmodule SpatoWeb.VehicleBookingLive.AdminShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-xl font-semibold mb-4">Butiran Tempahan Kenderaan</h2>

      <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4">
        <div>
          <dt class="font-medium text-gray-700">Tujuan</dt>
          <dd class="text-gray-900"><%= @vehicle_booking.purpose %></dd>
        </div>

        <div>
          <dt class="font-medium text-gray-700">Destinasi</dt>
          <dd class="text-gray-900"><%= @vehicle_booking.trip_destination %></dd>
        </div>

        <div>
          <dt class="font-medium text-gray-700">Masa Pickup</dt>
          <dd class="text-gray-900"><%= @vehicle_booking.pickup_time %></dd>
        </div>

        <div>
          <dt class="font-medium text-gray-700">Masa Pulang</dt>
          <dd class="text-gray-900"><%= @vehicle_booking.return_time %></dd>
        </div>

        <div>
          <dt class="font-medium text-gray-700">Status</dt>
          <dd class="text-gray-900"><%= @vehicle_booking.status %></dd>
        </div>

        <div class="sm:col-span-2">
          <dt class="font-medium text-gray-700">Catatan Tambahan</dt>
          <dd class="text-gray-900"><%= @vehicle_booking.additional_notes %></dd>
        </div>
      </dl>

      <div class="mt-6 flex gap-2">
        <%= if @vehicle_booking.status == "pending" do %>
          <.button phx-click="approve" phx-value-id={@vehicle_booking.id} class="bg-green-600 text-white">Luluskan</.button>
          <.button phx-click="reject" phx-value-id={@vehicle_booking.id} class="bg-red-600 text-white">Tolak</.button>
        <% else %>
          <span class="text-gray-500">Tiada tindakan tersedia</span>
        <% end %>
      </div>
    </div>
    """
  end
end
