defmodule SpatoWeb.MeetingRoomBookingLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Bookings
  alias Spato.Bookings.MeetingRoomBooking

  @impl true
  def mount(_params, session, socket) do
  user = Spato.Accounts.get_user_by_session_token(session["user_token"])

  bookings = Bookings.list_meeting_room_bookings_by_user(user.id)
  summary  = Bookings.booking_summary_user(user.id)

  {:ok,
    socket
    |> assign(:current_user, user)
    |> assign(:summary, summary)
    |> assign(:active_tab, "manage_meeting_rooms")
    |> assign(:sidebar_open, true)
    |> stream(:meeting_room_bookings, bookings)}
end

@impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Meeting room booking")
    |> assign(:meeting_room_booking, Bookings.get_meeting_room_booking!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Meeting room booking")
    |> assign(:meeting_room_booking, %MeetingRoomBooking{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Meeting room bookings")
    |> assign(:meeting_room_booking, nil)
  end

  @impl true
  def handle_info({SpatoWeb.MeetingRoomBookingLive.FormComponent, {:saved, meeting_room_booking}}, socket) do
    {:noreply, stream_insert(socket, :meeting_room_bookings, meeting_room_booking)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting_room_booking = Bookings.get_meeting_room_booking!(id)
    {:ok, _} = Bookings.delete_meeting_room_booking(meeting_room_booking)

    {:noreply, stream_delete(socket, :meeting_room_bookings, meeting_room_booking)}
  end

  @impl true
  def render(assigns) do
    ~H"""


      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div class="p-4 bg-blue-100 rounded-xl shadow">
          <h3 class="text-sm font-medium">Aktiviti Tempahan Bilik</h3>
          <p class="text-2xl font-bold"><%= @summary.total %></p>
        </div>

        <div class="p-4 bg-yellow-100 rounded-xl shadow">
          <h3 class="text-sm font-medium">Menunggu Kelulusan</h3>
          <p class="text-2xl font-bold"><%= @summary.pending %></p>
        </div>

        <div class="p-4 bg-green-100 rounded-xl shadow">
          <h3 class="text-sm font-medium">Tempahan Bulan Ini</h3>
          <p class="text-2xl font-bold"><%= @summary.this_month %></p>
        </div>
      </div>



      <.table
        id="meeting_room_bookings"
        rows={@streams.meeting_room_bookings}
        row_click={fn {_id, meeting_room_booking} -> JS.navigate(~p"/meeting_room_bookings/#{meeting_room_booking}") end}
      >
        <:col :let={{_id, meeting_room_booking}} label="Purpose">{meeting_room_booking.purpose}</:col>
        <:col :let={{_id, meeting_room_booking}} label="Participants">{meeting_room_booking.participants}</:col>
        <:col :let={{_id, meeting_room_booking}} label="Start time">{meeting_room_booking.start_time}</:col>
        <:col :let={{_id, meeting_room_booking}} label="End time">{meeting_room_booking.end_time}</:col>
        <:col :let={{_id, meeting_room_booking}} label="Is recurring">{meeting_room_booking.is_recurring}</:col>
        <:col :let={{_id, meeting_room_booking}} label="Recurrence pattern">{meeting_room_booking.recurrence_pattern}</:col>
        <:col :let={{_id, meeting_room_booking}} label="Status">{meeting_room_booking.status}</:col>
        <:col :let={{_id, meeting_room_booking}} label="Notes">{meeting_room_booking.notes}</:col>
        <:action :let={{_id, meeting_room_booking}}>
          <div class="sr-only">
            <.link navigate={~p"/meeting_room_bookings/#{meeting_room_booking}"}>Show</.link>
          </div>
          <.link patch={~p"/meeting_room_bookings/#{meeting_room_booking}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, meeting_room_booking}}>
          <.link
            phx-click={JS.push("delete", value: %{id: meeting_room_booking.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal :if={@live_action in [:new, :edit]} id="meeting_room_booking-modal" show on_cancel={JS.patch(~p"/meeting_room_bookings")}>
        <.live_component
          module={SpatoWeb.MeetingRoomBookingLive.FormComponent}
          id={@meeting_room_booking.id || :new}
          title={@page_title}
          action={@live_action}
          meeting_room_booking={@meeting_room_booking}
          patch={~p"/meeting_room_bookings"}
        />
      </.modal>
      """

  end
end
