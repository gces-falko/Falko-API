require "rest-client"

class ProjectsController < ApplicationController
  include ValidationsHelper
  include ProjectsDoc

  before_action :set_project, only: [:destroy, :show, :get_contributors]

  before_action only: [:index, :create] do
    validate_user(params[:user_id])
  end

  before_action only: [:show, :update, :destroy] do
    validate_project(params[:id])
  end

  def index
    @projects = User.find(params[:user_id]).projects
    render json: @projects
  end

  def github_projects_list
    client = Adapter::GitHubProject.new(request)

    user_login = client.get_github_user

    @form_params_user = { user: [] }
    @form_params_user[:user].push(login: user_login)

    user_repos = []

    (client.get_github_repos(user_login)).each do |repo|
      user_repos.push(repo.name)
    end

    @form_params_user[:user].push(repos: user_repos)

    @form_params_orgs = { orgs: [] }

    (client.get_github_orgs(user_login)).each do |org|
      repos_names = []
      (client.get_github_orgs_repos(org)).each do |repo|
        repos_names.push(repo.name)
      end
      @form_params_orgs[:orgs].push(name: org.login, repos: repos_names)
    end

    @form_params_user_orgs = @form_params_orgs.merge(@form_params_user)

    render json: @form_params_user_orgs
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
      params.require(:project).permit(:name, :description, :user_id, :is_project_from_github, :github_slug, :is_scoring)
    end
end
