module MetricHelper
  include BurndownHelper
  include VelocityHelper

  def get_metrics(grade)
    last_release = grade.project.releases.last
    if last_release.blank?
      return nil
    else
      metrics = calculate_metrics(last_release)

      if metrics.blank?
        final_metric = 0
      else
        sum_of_weights = grade.weight_debts + grade.weight_velocity + grade.weight_burndown

        final_metric = (Float (grade.weight_debts * metrics[:metric_debts_value]) +
                              (grade.weight_velocity * metrics[:metric_velocity_value]) +
                              (grade.weight_burndown * metrics[:metric_burndown_value])) /
                              sum_of_weights
      end

      return final_metric.round(1)
    end
  end

  def calculate_metrics(release)
    sprint = release.sprints.last
    if sprint.blank? || sprint.stories.blank?
      return nil
    else
      if release.project.is_scoring == true
        burned_stories = {}
        date_axis = []
        points_axis = []
        ideal_line = []

        velocity = get_sprints_informations(release.sprints, sprint)
        total_points = get_total_points(sprint)
        burned_stories = get_burned_points(sprint, burned_stories)
        total_sprints_points = velocity[:total_points]
        velocities = velocity[:velocities]
        range_dates = (sprint.initial_date .. sprint.final_date)

        set_dates_and_points(burned_stories, date_axis, points_axis, range_dates, total_points)
        set_ideal_line(date_axis.length - 1, ideal_line, total_points)

        planned_points = calculate_points(release, velocity, total_points)
        burned_points = calculate_points(release, velocity, completed_points)
        
        total_points = get_total_points_release(release) 
        metric_burndown_value = calculate_burndown(date_axis, points_axis, (ideal_line[0] - ideal_line[1]))
        metric_debts_value = calculate_velocity_and_debt(Float(planned_points - burned_points) / planned_points)
        metric_velocity_value = calculate_metric_velocity_value(release.sprints.count, total_sprints_points, velocities, total_points)
        metric_velocity_value = calculate_velocity_and_debt(metric_velocity_value)

        return metrics = { metric_debts_value: metric_debts_value,
                    metric_velocity_value: metric_velocity_value,
                    metric_burndown_value: metric_burndown_value }
      end
    end
  end

  def calculate_velocity_and_debt(metric)
    values = 0

    if metric <= 0.2
      values += 4
    elsif metric <= 0.4
      values += 3
    elsif metric <= 0.6
      values += 2
    elsif metric <= 0.9
      values += 1
    elsif metric <= 1
      values += 0
    end

    return values
  end

  def calculate_burndown(date_axis, points_axis, ideal_burned_points)
    for i in 0..(date_axis.length - 2)
      real_burned_points = points_axis[i] - points_axis[i + 1]
      burned_percentage = Float((real_burned_points).abs * 100) / ideal_burned_points
      metric_burndown_array.push(burned_percentage)
    end

    values = 0

    for i in 0..(metric_burndown_array.length - 1)
      if metric_burndown_array[i] <= 10 || metric_burndown_array[i] >= 200
        values += 0
      elsif metric_burndown_array[i] <= 40
        values += 1
      elsif metric_burndown_array[i] <= 60
        values += 2
      elsif metric_burndown_array[i] <= 80
        values += 3
      elsif metric_burndown_array[i] <= 100
        values += 4
      end
    end

    return Float values / metric_burndown_array.length
  end

  def calculate_metric_burndown_array(date_axis, points_axis, ideal_burned_points)
    for i in 0..(date_axis.length - 2)
      real_burned_points = points_axis[i] - points_axis[i + 1]
      burned_percentage = Float((real_burned_points).abs * 100) / ideal_burned_points
      metric_burndown_array.push(burned_percentage)
    end
    return metric_burndown_array
  end

  def calculate_metric_velocity_value(amount_of_sprints, total_sprints_points, velocities, total_points)
    metric_velocity_value = 0
    for i in 0..(amount_of_sprints - 1)
      metric_velocity_value += (total_sprints_points[i] - velocities[i])
    end
    return Float metric_velocity_value / total_points
  end

  def calculate_points(release, velocity, range)
    points = 0
    for i in 0..(release.sprints.length - 1)
      points += velocity[:range][i]
    end
    return points
  end
end
