class RetrospectivesController < ApplicationController
  include ValidationsHelper
  include RetrospectivesDoc

  before_action :set_retrospective, only: [:show, :update, :destroy]

  before_action only: [:index, :create] do
    validate_sprint(params[:sprint_id])
  end

  before_action only: [:show, :update, :destroy] do
    validate_sprint_retrospective(params[:id])
  end


  def index
    @retrospective = @sprint.retrospective

    if @retrospective == nil
      @retrospective = []
    end

    render json: @retrospective
  end

  def save_retrospective
    @retrospective.sprint_id = @sprint.id
    if @retrospective.save
      render json: @retrospective, status: :created
    else
      render json: @retrospective.errors, status: :unprocessable_entity
    end
  end

  def create
    if @sprint.retrospective.nil?
      @retrospective = Retrospective.create(retrospective_params)
      save_retrospective
    else
      render json: { error: "Cannot create multiple retrospectives" }, status: 403
    end
  end

  def show
    render json: @retrospective
  end

  def update
    if @retrospective.update(retrospective_params)
      render json: @retrospective
    else
      render json: @retrospective.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @retrospective.destroy
  end

  private
    def set_retrospective
      @retrospective = Retrospective.find(params[:id])
    end

    def retrospective_params
      params.require(:retrospective).permit(:sprint_report, positive_points: [], negative_points: [] , improvements: [])
    end
end
