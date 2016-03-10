class SchedulesController < ApplicationController

  def index
    @cohort = Cohort.find_by_name(params[:cohort_slug])
    @schedules = @cohort.schedules
    render 'cohorts/schedules/index'
  end
  def new
    @cohort = Cohort.find_by_name(params[:cohort_slug])
    @schedule= Schedule.new_for_form
    render "cohorts/schedules/new"
  end

  def create
    @cohort = Cohort.find_by_name(params[:cohort_slug])
    @schedule = Schedule.create_from_params(schedule_params, @cohort)
    @schedule.build_labs(validated_labs_params)
    @schedule.build_activities(validated_activity_params)
    if @schedule.save
      redirect_to cohort_schedule_path(@cohort, @schedule)
    else
      render 'cohorts/schedules/new'
    end
  end
  
  def edit
    @cohort = Cohort.find_by_name(params[:cohort_slug])
    @schedule = Schedule.find_by(slug: params[:slug])
    render 'cohorts/schedules/edit'
  end

  def show
    # binding.pry
    @schedule = Schedule.find_by(slug: params[:slug])
    page = render 'cohorts/schedules/show'
    if creating_schedule
      GithubWrapper.new(@schedule.cohort, @schedule, page).create_repo_schedules
    elsif updating_schedule
      GithubWrapper.new(@schedule.cohort, @schedule, page).update_repo_schedules
    end
  end


  def update
    @schedule = Schedule.find_by(slug: params[:slug])
    @schedule.update_from_params(schedule_params)
    @schedule.update_labs(schedule_params)
    @schedule.update_activities(schedule_params)
    if @schedule.save
      redirect_to cohort_schedule_path(@schedule.cohort, @schedule)
    else
      render 'cohorts/schedules/edit'
    end
  end

  private
  def schedule_params
    params.require(:schedule).permit(:week, :day, :date, :notes, :labs_attributes => [:id, :name], :activities_attributes => [:id, :time, :description, :reserve_room])  
  end

  def validated_activity_params
    schedule_params["activities_attributes"].delete_if {|num, activity_hash| activity_hash["time"].empty? || activity_hash["description"].empty?}
  end

  def validated_labs_params
    schedule_params["labs_attributes"].delete_if {|num, lab_hash| lab_hash["name"].empty?}
  end

  def creating_schedule
    request.referrer.split("/").last == "new"
  end

  def updating_schedule
    request.referrer.split("/").last == "edit"
  end


  # def need_to_update_github?
  #   request.referrer.split("/").last == "edit" || request.referrer.split("/").last == "new"
  # end

end
