defmodule SpatoWeb.Router do
  use SpatoWeb, :router

  import SpatoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SpatoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :user_auth do
    plug :require_authenticated_user
  end

  pipeline :regular_user_auth do
    plug :require_authenticated_user
    plug :require_authenticated_regular_user
  end

  pipeline :admin_auth do
    plug :require_authenticated_user
    plug :require_authenticated_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpatoWeb do
    pipe_through :browser

    live "/", UserLoginLive
  end

  scope "/", SpatoWeb do
    pipe_through [:browser, :regular_user_auth]
    live "/dashboard", UserDashboardLive
    # Add more user LiveViews here
    live "/vehicle_bookings", VehicleBookingLive.Index, :index
    live "/vehicle_bookings/new", VehicleBookingLive.Index, :new
    live "/vehicle_bookings/:id/edit", VehicleBookingLive.Index, :edit
    live "/vehicle_bookings/:id", VehicleBookingLive.Index, :show
    live "/available_vehicles", AvailableVehicleLive

    live "/catering_bookings", CateringBookingLive.Index, :index
    live "/catering_bookings/new", CateringBookingLive.Index, :new
    live "/catering_bookings/:id/edit", CateringBookingLive.Index, :edit
    live "/catering_bookings/:id", CateringBookingLive.Index, :show
    live "/available_catering", AvailableCateringLive
    live "/meeting_room_bookings", MeetingRoomBookingLive.Index, :index
    live "/meeting_room_bookings/new", MeetingRoomBookingLive.Index, :new
    live "/meeting_room_bookings/:id/edit", MeetingRoomBookingLive.Index, :edit

    live "/meeting_room_bookings/:id", MeetingRoomBookingLive.Index, :show
    live "/meeting_room_bookings/:id/show/edit", MeetingRoomBookingLive.Show, :edit
    live "/available_rooms", AvailableRoomLive
  end

  scope "/admin", SpatoWeb do
    pipe_through [:browser, :admin_auth]

    live_session :admin_only,
      on_mount: [{SpatoWeb.UserAuth, :ensure_admin}] do

      live "/dashboard", AdminDashboardLive
      # Add more admin-only LiveViews here
      live "/departments", DepartmentLive.Index, :index
      live "/departments/new", DepartmentLive.Index, :new
      live "/departments/:id/edit", DepartmentLive.Index, :edit
      live "/departments/:id", DepartmentLive.Index, :show

      live "/user_profiles", UserProfileLive.Index, :index
      live "/user_profiles/:id", UserProfileLive.Index, :show

      live "/vehicles", VehicleLive.Index, :index
      live "/vehicles/new", VehicleLive.Index, :new
      live "/vehicles/:id/edit", VehicleLive.Index, :edit
      live "/vehicles/:id", VehicleLive.Index, :show

      live "/equipments", EquipmentLive.Index, :index
      live "/equipments/new", EquipmentLive.Index, :new
      live "/equipments/:id/edit", EquipmentLive.Index, :edit
      live "/equipments/:id", EquipmentLive.Index, :show

      live "/meeting_rooms", MeetingRoomLive.Index, :index
      live "/meeting_rooms/new", MeetingRoomLive.Index, :new
      live "/meeting_rooms/:id/edit", MeetingRoomLive.Index, :edit
      live "/meeting_rooms/:id", MeetingRoomLive.Index, :show

      live "/catering_menus", CateringMenuLive.Index, :index
      live "/catering_menus/new", CateringMenuLive.Index, :new
      live "/catering_menus/:id/edit", CateringMenuLive.Index, :edit
      live "/catering_menus/:id", CateringMenuLive.Index, :show

      live "/vehicle_bookings", VehicleBookingLive.AdminIndex, :index
      live "/vehicle_bookings/:id", VehicleBookingLive.AdminIndex, :show

      live "/catering_bookings", CateringBookingLive.AdminIndex, :index
      live "/catering_bookings/:id", CateringBookingLive.AdminIndex, :show

      live "/meeting_room_bookings", MeetingRoomBookingLive.AdminIndex, :index
      live "/meeting_room_bookings/:id", MeetingRoomBookingLive.AdminIndex, :show

    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SpatoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:spato, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SpatoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SpatoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{SpatoWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", SpatoWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{SpatoWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", SpatoWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{SpatoWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
