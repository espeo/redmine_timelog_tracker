resources :timelog_tracker, :only => [] do
  collection do
    post :start
    match :update, via: :patch
    post :cancel
    post :commit
  end
end
