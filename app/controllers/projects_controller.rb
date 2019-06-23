require "rest-client"

class ProjectsController < ApplicationController
  include ValidationsHelper
  include ProjectsDoc

  before_action :set_project, only: [:destroy, :show, :get_contributors]

  before_action only: [:index, :create] do
    validate_user(0, :user_id)
  end

  before_action only: [:show, :update, :destroy] do
    validate_project(:id, 0)
  end

  def index
    @projects = User.find(params[:user_id]).projects
    render json: @projects
  end

  def github_projects_list
    client = Adapter::GitHubProject.new(request)

    @form_user_params = get_user_params(client)
    @form_orgs_params = get_orgs_params(client)
    @form_user_and_orgs_params = @form_orgs_params.merge(@form_user_params)

    render json: @form_user_and_orgs_params
  end

  def show
    render json: @project
  end

  def create
    @project = Project.create(project_params)
    @project.user_id = @current_user.id

    if @project.save
      render json: @project, status: :created
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      render json: @project
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
  end

  def get_contributors
    client = Adapter::GitHubProject.new(request)

    contributors = []

    (client.get_contributors(@project.github_slug)).each do |contributor|
      contributors.push(contributor.login)
    end

    render json: contributors, status: :ok
  end

  private
    def set_project
      begin
        @project = Project.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { errors: "Project not found" }, status: :not_found
      end
    end

    def project_params
      params.require(:project).permit(:name,
                                      :description,
                                      :user_id,
                                      :is_project_from_github,
                                      :github_slug,
                                      :is_scoring)
    end

    def get_user_params(client)
      user_login = client.get_github_user

      user_params = { user: [] }
      user_params[:user].push(login: user_login)

      user_repos = []

      (client.get_github_repos(user_login)).each do |repo|
        user_repos.push(repo.name)
      end

      user_params[:user].push(repos: user_repos)

      return user_params
    end

    def get_orgs_params(client)
      user_login = client.get_github_user

      orgs_params = { orgs: [] }

      (client.get_github_orgs(user_login)).each do |org|
        repos_names = []
        (client.get_github_orgs_repos(org)).each do |repo|
          repos_names.push(repo.name)
        end
        orgs_params[:orgs].push(name: org.login, repos: repos_names)
      end

      return orgs_params
    end
end
