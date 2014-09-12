resources :timelog_tracker, :only => [] do
  collection do
    get :autocomplete_issues
    post :start
    match :update, via: :patch
    post :cancel
    post :commit
  end
end
