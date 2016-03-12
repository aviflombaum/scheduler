require 'rails_helper'

feature "CreateNewCohorts", :type => :feature do
  describe "create new cohort" do
    it "lets you create a new cohort" do
      sign_in
      visit '/cohorts/new'
      fill_in "Name", with: "web-1115"
      click_button 'Create Cohort'
      expect(current_path).to eq('/cohorts/web-1115')
      expect(page.body).to include('web-1115')
    end
  end

  describe "edit an exist cohort" do 
    it "edits a cohort" do 
      cohort = FactoryGirl.build(:cohort)
      cohort.save

      sign_in
      visit "/cohorts/#{cohort.name}"
      click_link "edit"
      fill_in "Name", with: "web-1120"
      click_button "Update Cohort"
      expect(current_path).to eq('/cohorts/web-1120')
      expect(page.body).to include('web-1120')
    end
  end
end
