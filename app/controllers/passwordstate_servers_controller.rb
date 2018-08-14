class PasswordstateServersController < ::ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  include Foreman::Controller::Parameters::PasswordstateServer

  before_action :find_server, except: %i[index new create test_connection]

  def index
    @passwordstate_servers = resource_base_search_and_page
  end

  def show; end

  def new
    @passwordstate_server = PasswordstateServer.new
  end

  def edit; end

  def create
    @passwordstate_server = PasswordstateServer.new(passwordstate_server_params)
    if @passwordstate_server.save
      process_success success_redirect: passwordstate_server_path(@passwordstate_server)
    else
      process_error
    end
  end

  def update
    if @passwordstate_server.update(passwordstate_server_params)
      process_success
    else
      process_error
    end
  end

  def destroy
    if @passwordstate_server.destroy
      process_success
    else
      process_error
    end
  end

  def test_connection
    # passwordstate_id is posted from AJAX function. passwordstate_id is nil if new
    if params[:passwordstate_id].present?
      @passwordstate_server = PasswordstateServer.authorized(:edit_passwordstate_server).find(params[:passwordstate_id])
      @passwordstate_server.attributes = passwordstate_server_params.reject { |k, v| k == :password && v.blank? }
    else
      @passwordstate_server = PasswordstateServer.new(passwordstate_server_params)
    end

    @passwordstate_server.test_connection
    render partial: 'form', locals: { passwordstate_server: @passwordstate_server }
  end

  def folders
    @passwordstate_server.folders
  end

  def password_lists
    @passwordstate_server.password_lists
  end

  private

  def find_server
    @passwordstate_server = PasswordstateServer.find(params[:id])
  end
end
