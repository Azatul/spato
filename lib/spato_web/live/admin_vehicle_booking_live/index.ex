defmodule SpatoWeb.AdminVehicleBookingLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Bookings.VehicleBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Senarai Tempahan Kenderaan")
     |> assign(:active_tab, "vehicles")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:vehicle_bookings, Bookings.list_vehicle_bookings())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({SpatoWeb.AdminVehicleBookingLive.FormComponent, {:saved, vehicle_booking}}, socket) do
    {:noreply, stream_insert(socket, :vehicle_bookings, vehicle_booking)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
def handle_event("approve", %{"id" => id}, socket) do
  vehicle_booking = Bookings.get_vehicle_booking!(id)
  {:ok, updated} = Bookings.update_vehicle_booking(vehicle_booking, %{status: "approved"})
  {:noreply, stream_insert(socket, :vehicle_bookings, updated)}
end

def handle_event("reject", %{"id" => id}, socket) do
  vehicle_booking = Bookings.get_vehicle_booking!(id)
  {:ok, updated} = Bookings.update_vehicle_booking(vehicle_booking, %{status: "rejected"})
  {:noreply, stream_insert(socket, :vehicle_bookings, updated)}
end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <div class="flex flex-col flex-1">
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

        <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
          <section class="mb-4">
            <h1 class="text-xl font-bold mb-1">Senarai Tempahan Kenderaan</h1>
            <p class="text-md text-gray-500 mb-4">Semak dan urus tempahan kenderaan</p>

            <section class="mb-4 flex justify-end">
              <.link patch={~p"/admin/vehicle_bookings/new"}>
                <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Tempahan Baharu</.button>
              </.link>
            </section>

            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <.table
                id="vehicle_bookings"
                rows={@streams.vehicle_bookings}
                row_click={fn {_id, vehicle_booking} ->
                  JS.navigate(~p"/admin/vehicle_bookings/#{vehicle_booking}")
                end}
              >
                <:col :let={{_id, vehicle_booking}} label="Purpose">{vehicle_booking.purpose}</:col>
                <:col :let={{_id, vehicle_booking}} label="Trip destination">{vehicle_booking.trip_destination}</:col>
                <:col :let={{_id, vehicle_booking}} label="Pickup time">{vehicle_booking.pickup_time}</:col>
                <:col :let={{_id, vehicle_booking}} label="Return time">{vehicle_booking.return_time}</:col>
                <:col :let={{_id, vehicle_booking}} label="Status">
                  <span class={
                    case vehicle_booking.status do
                      "approved" -> "text-green-600 font-bold"
                      "rejected" -> "text-red-600 font-bold"
                      _ -> "text-gray-600"
                    end
                  }>
                    <%= String.capitalize(vehicle_booking.status) %>
                  </span>
                </:col>
                <:col :let={{_id, vehicle_booking}} label="Additional notes">{vehicle_booking.additional_notes}</:col>
                <:col :let={{_id, vehicle_booking}} label="Rejection reason">{vehicle_booking.rejection_reason}</:col>
                <:action :let={{_id, vehicle_booking}}>
                  <div class="sr-only">
                    <.link navigate={~p"/admin/vehicle_bookings/#{vehicle_booking}"}>Show</.link>
                  </div>
                </:action>
                <:action :let={{_id, vehicle_booking}}>
                  <%= if vehicle_booking.status == "pending" do %>
                    <.link
                      phx-click={JS.push("approve", value: %{id: vehicle_booking.id})}
                      class="text-green-600"
                    >
                      Approve
                    </.link>
                    <.link
                      phx-click={JS.push("reject", value: %{id: vehicle_booking.id})}
                      class="text-red-600 ml-2"
                    >
                      Reject
                    </.link>
                  <% else %>
                    <span><%= vehicle_booking.status %></span>
                  <% end %>
                </:action>

              </.table>
            </section>

            <.modal :if={@live_action in [:new, :edit]} id="vehicle_booking-modal" show on_cancel={JS.patch(~p"/admin/vehicle_bookings")}>
              <.live_component
                module={SpatoWeb.AdminVehicleBookingLive.FormComponent}
                id={:new}
                title={@page_title}
                action={@live_action}
                vehicle_booking={%VehicleBooking{}}
                patch={~p"/admin/vehicle_bookings"}
              />
            </.modal>
          </section>
        </main>
      </div>
    </div>
    """
  end
end
