module UserValidationHelper
  def get_current_user
    @current_user = AuthorizeApiRequest.call(request.headers).result
  end

  def get_user(id)
    @user = User.find(id.to_i)
  end

  def get_project_user
    @user = User.find(@project.user_id)
  end

  def validate_user_authorization
    if @current_user.id == @user.id
      return true
    else
      render json: { error: "Not Authorized" }, status: 401
    end
  end

  def validate_user(user_id)
    get_current_user
    get_user(user_id)

    validate_user_authorization
  end
end
