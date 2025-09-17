defmodule SpatoWeb.EquipmentBookingLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Bookings.EquipmentBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
    socket
    |> assign(:page_title, "Senarai Tempahan Peralatan")
    |> assign(:active_tab, "equipments")
    |> assign(:sidebar_open, true)
    |> assign(:current_user, socket.assigns.current_user)
    |> stream(:equipment_bookings, Bookings.list_equipment_bookings())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Equipment booking")
    |> assign(:equipment_booking, Bookings.get_equipment_booking!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Equipment booking")
    |> assign(:equipment_booking, %EquipmentBooking{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Equipment bookings")
    |> assign(:equipment_booking, nil)
  end

  @impl true
  def handle_info({SpatoWeb.EquipmentBookingLive.FormComponent, {:saved, equipment_booking}}, socket) do
    {:noreply, stream_insert(socket, :equipment_bookings, equipment_booking)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    equipment_booking = Bookings.get_equipment_booking!(id)
    {:ok, _} = Bookings.delete_equipment_booking(equipment_booking)

    {:noreply, stream_delete(socket, :equipment_bookings, equipment_booking)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def render(assigns) do
    ~H"""
     <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
        <div class="flex flex-col flex-1">
          <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

          <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
          <section class="mb-4">
              <h1 class="text-xl font-bold mb-1">Senarai Tempahan Peralatan</h1>
              <p class="text-md text-gray-500 mb-4">Semak semua tempahan peralatan yang anda buat</p>

        <!-- Middle Section: Add Equipment Button -->
        <section class="mb-4 flex justify-end">
          <.link patch={~p"/available_equipments"}>
                <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Tempah Peralatan</.button>
              </.link>
        </section>


          <.table
            id="equipment_bookings"
            rows={@streams.equipment_bookings}
            row_click={fn {_id, equipment_booking} -> JS.navigate(~p"/equipment_bookings/#{equipment_booking}") end}
          >
            <:col :let={{_id, equipment_booking}} label="Quantity">{equipment_booking.quantity}</:col>
            <:col :let={{_id, equipment_booking}} label="Location">{equipment_booking.location}</:col>
            <:col :let={{_id, equipment_booking}} label="Usage date">{equipment_booking.usage_date}</:col>
            <:col :let={{_id, equipment_booking}} label="Return date">{equipment_booking.return_date}</:col>
            <:col :let={{_id, equipment_booking}} label="Usage time">{equipment_booking.usage_time}</:col>
            <:col :let={{_id, equipment_booking}} label="Return time">{equipment_booking.return_time}</:col>
            <:col :let={{_id, equipment_booking}} label="Additional notes">{equipment_booking.additional_notes}</:col>
            <:col :let={{_id, equipment_booking}} label="Condition before">{equipment_booking.condition_before}</:col>
            <:col :let={{_id, equipment_booking}} label="Condition after">{equipment_booking.condition_after}</:col>
            <:col :let={{_id, equipment_booking}} label="Status">{equipment_booking.status}</:col>
            <:action :let={{_id, equipment_booking}}>
              <div class="sr-only">
                <.link navigate={~p"/equipment_bookings/#{equipment_booking}"}>Show</.link>
              </div>
              <.link patch={~p"/equipment_bookings/#{equipment_booking}/edit"}>Edit</.link>
            </:action>
            <:action :let={{id, equipment_booking}}>
              <.link
                phx-click={JS.push("delete", value: %{id: equipment_booking.id}) |> hide("##{id}")}
                data-confirm="Are you sure?"
              >
                Delete
              </.link>
            </:action>
          </.table>

          <.modal :if={@live_action in [:new, :edit]} id="equipment_booking-modal" show on_cancel={JS.patch(~p"/equipment_bookings")}>
            <.live_component
              module={SpatoWeb.EquipmentBookingLive.FormComponent}
              id={@equipment_booking.id || :new}
              title={@page_title}
              action={@live_action}
              equipment_booking={@equipment_booking}
              patch={~p"/equipment_bookings"}
            />
          </.modal>
        </section>
      </main>
      </div>
    </div>
    """
  end
end
