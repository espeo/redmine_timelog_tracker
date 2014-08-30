resources :timelog_tracker, :only => [] do
  collection do
    post :start
    post :cancel
    post :commit
  end
end
