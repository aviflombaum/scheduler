Rails.application.routes.draw do
  resources :cohorts, param: :slug do 
    resources :schedules, param: :slug
    # post "/cohorts/:cohort_slug/schedules", to: "schedules#create", as: "/schedules"
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
  root "cohorts#new"
end
