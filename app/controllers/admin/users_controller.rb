class Admin::UsersController < Admin::BaseController
  has_filters %w{without_confirmed_hide all with_confirmed_hide}, only: :index

  before_action :load_user, only: [:confirm_hide, :restore, :erase]

  def index
    @users = User.only_hidden.not_erased.send(@current_filter).page(params[:page])
  end

  def show
    @user = User.with_hidden.find(params[:id])
    @debates = @user.debates.with_hidden.page(params[:page])
    @comments = @user.comments.with_hidden.page(params[:page])
  end

  def confirm_hide
    @user.confirm_hide
    redirect_to request.query_parameters.merge(action: :index)
  end

  def restore
    @user.restore
    Activity.log(current_user, :restore, @user)
    redirect_to request.query_parameters.merge(action: :index)
  end

  def erase
    @user = User.with_hidden.find(params[:id])

    @user.erase("Borrado polo administrador")
    redirect_to request.query_parameters.merge(action: :index), notice: t("admin.users.index.erase_user_notice")
  end

  private

    def load_user
      @user = User.with_hidden.find(params[:id])
    end

end
