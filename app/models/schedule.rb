class Schedule < ApplicationRecord
  include HTTParty
  has_many :schedule_labs
  has_many :schedule_activities
  has_many :activities, through: :schedule_activities
  has_many :labs, through: :schedule_labs
  has_many :objectives, dependent: :destroy
  has_many :calendar_events
  has_many :blog_assignments
  belongs_to :cohort
  accepts_nested_attributes_for :labs
  accepts_nested_attributes_for :activities
  accepts_nested_attributes_for :objectives
  validates :date, presence: true

  before_create :slugify

  def slugify
    self.slug = self.date.strftime("%b %d, %Y").downcase.gsub(/[\s,]+/, '-')
  end

  def to_param
    self.slug
  end

  def self.new_for_form
    schedule = Schedule.new

    3.times do
      schedule.objectives << Objective.new
    end

    3.times do
      schedule.labs << Lab.new
    end

    10.times do
      schedule.activities << Activity.new
    end

    schedule
  end

  def self.create_from_params(schedule_params, cohort)
    Schedule.new(week: schedule_params["week"],
      day: schedule_params["day"],
      date: schedule_params["date"],
      notes: schedule_params["notes"],
      deploy: schedule_params["deploy"],
      cohort: cohort)
  end

  def build_labs(valided_labs_params)
    valided_labs_params.each do |num, lab_hash|
      lab = Lab.find_by(name: lab_hash["name"]) || Lab.new(name: lab_hash["name"])
      self.labs << lab
    end
  end

  def build_activities(validated_activity_params)
    validated_activity_params.each do |num, activity_hash|
      activity = Activity.find_by(start_time: activity_hash["start_time"], end_time: activity_hash["end_time"], description: activity_hash["description"]) || Activity.new(start_time: activity_hash["start_time"], end_time: activity_hash["end_time"], description: activity_hash["description"])
      self.activities << activity
    end
  end

  def build_objectives(validated_objectives_params)
    validated_objectives_params.each do |num, objective_hash|
      objective = Objective.find_by(content: objective_hash[:content]) || Objective.new(content: objective_hash[:content])
      self.objectives << objective
      objective.schedule = self
    end
  end

  def update_from_params(schedule_params)
    self.update(notes: schedule_params["notes"], deploy: schedule_params["deploy"])
  end

  def update_labs(schedule_params)
    schedule_params["labs_attributes"].each do |num, lab_hash|
      lab = Lab.find(lab_hash[:id])
      lab.update(lab_hash)
      lab.save
    end
  end

  def update_activities(schedule_params)
    schedule_params["activities_attributes"].each do |num, activity_hash|
      activity = Activity.find(activity_hash[:id])
      activity.update(activity_hash)
      activity.save
    end
  end

  def pretty_date
    self.date.strftime("%A, %d %b %Y")
  end

  def reservation_activities
    self.activities.reject { |a| !a.reserve_room }
  end

  def deployed?
    !!self.deployed_on
  end

  def get_blogs
    assignments = HTTParty.get("#{ENV['BLOG_API_ENDPOINT']}/api/cohorts/#{self.cohort.name}/blog_assignments/#{self.date_for_api_call}")
    if !assignments.empty?
      assignments["schedules"].each do |assignment|
        binding.pry
        student = Student.find_by(first_name: assignment["user"]["first_name"], last_name: assignment["user"]["last_name"])
        if assignment["user"]["blog"]
          student.blog_url = assignment["user"]["blog"]["url"]
          student.save
        end
        blog_assignment = BlogAssignment.create(student: student, schedule: self, due_date: assignment["due_date"])
        self.blog_assignments << blog_assignment
        self.save
      end
    end
  end

  def date_for_api_call
    self.date.strftime("%Y-%m-%d")
  end

end
