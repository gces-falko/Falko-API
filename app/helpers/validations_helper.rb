module ValidationsHelper
  include UserValidationHelper

  def get_release_project
    @project = Project.find(@release.project_id)
  end

  def get_grade_project
    @project = Project.find(@grade.project.id)
  end

  def get_sprint_release
    @release = Release.find(@sprint.release_id)
  end
  
  def get_story_sprint
    @sprint = Sprint.find(@story.sprint_id)
  end

  def get_revision_sprint
    @sprint = Sprint.find(@revision.sprint_id)
  end

  def get_retrospective_sprint
    @sprint = Sprint.find(@retrospective.sprint_id)
  end

  def get_project(id)
    @project = Project.find(id.to_i)
  end

  def get_grade(id)
    @grade = Grade.find(id.to_i)
  end

  def get_release(id)
    @release = Release.find(id.to_i)
  end

  def get_sprint(id)
    @sprint = Sprint.find(id.to_i)
  end

  def get_story(id)
    @story = Story.find(id.to_i)
  end

  def get_revision(id)
    @revision = Revision.find(id.to_i)
  end

  def get_retrospective(id)
    @retrospective = Retrospective.find(id.to_i)
  end

  def validate_project(project_id)
    get_current_user
    get_project(project_id)
    get_project_user

    validate_authorization
  end

  def validate_grade(grade_id)
    get_current_user
    get_grade(grade_id)
    get_grade_project
    get_project_user

    validate_authorization
  end

  def validate_release(release_id)
    get_current_user
    get_release(release_id)
    get_release_project
    get_project_user

    validate_authorization
  end

  def validate_sprint(sprint_id)
    get_current_user
    get_sprint(sprint_id)
    get_sprint_release
    get_release_project
    get_project_user

    validate_authorization
  end

  def validate_sprint_dependencies
    get_current_user
    get_sprint_release
    get_release_project
    get_project_user

    validate_authorization
  end

  def validate_sprint_story(story_id)
    get_story(story_id)
    get_story_sprint
    
    validate_sprint_dependencies
  end

  def validate_sprint_revision(revision_id)
    get_revision(revision_id)
    get_revision_sprint
    
    validate_sprint_dependencies
  end

  def validate_sprint_retrospective(retrospective_id)
    get_retrospective(retrospective_id)
    get_retrospective_sprint
    
    validate_sprint_dependencies
  end

  def validate_sprints_date
    if @release.initial_date > @sprint.initial_date ||
       @release.final_date < @sprint.initial_date
      return false
    elsif @release.final_date < @sprint.final_date ||
          @release.initial_date > @sprint.final_date
      return false
    else
      return true
    end
  end

  def validate_stories(story_points, sprint_id)
    get_current_user
    get_sprint(sprint_id)
    get_sprint_release
    get_release_project
    get_project_user

    if @project.is_scoring
      unless story_points.nil?
        return true
      else
        return false
      end
    else
      unless story_points.nil?
        return false
      else
        return true
      end
    end
  end

  def update_amount_of_sprints
    @release.amount_of_sprints = @release.sprints.count
    @release.save
  end
end
