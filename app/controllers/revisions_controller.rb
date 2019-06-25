class RevisionsController < ApplicationController
  include ValidationsHelper
  include RevisionsDoc

  before_action :set_revision, only: [:show, :update]

  before_action only: [:index, :create] do
    validate_sprint(params[:sprint_id])
  end

  before_action only: [:show, :update, :destroy] do
    validate_sprint_revision(params[:id])
  end

  def index
    @revision = @sprint.revision
    render json: @revision
  end

  def save_revision
    @revision.sprint_id = @sprint.id
    if @revision.save
      render json: @revision, status: :created
    else
      render json: @revision.errors, status: :unprocessable_entity
    end
  end

  def create
    if @sprint.revision.nil?
      @revision = Revision.create(revision_params)
      save_revision
    else
      render json: { error: "Cannot create multiple revisions" }, status: 403
    end
  end

  def show
    render json: @revision
  end

  def update
    if @revision.update(revision_params)
      render json: @revision
    else
      render json: @revision.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @revision.destroy
  end

  private
    def set_revision
      @revision = Revision.find(params[:id])
    end

    def revision_params
      params.require(:revision).permit(done_report: [], undone_report: [])
    end
end
