# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

scope "projects/:project_id" do
  resources :inline_edit, only: %i[show update] do
    member do
      post :switch_close
    end
  end
  resources :gantt, controller: "gantt", only: [:index] do
    collection do
      get :task, to: "gantt#new_task"
      post :task, to: "gantt#create_task"
      get :filter_values, to: "gantt#filter_values"
      post :apply_filter, to: "gantt#apply_filter"
      put :update_width, to: "gantt#update_width"
      post :projects_list, to: "gantt#projects_list"
      post :chat, to: "gantt#chat_modal"
      post :import, to: "gantt#import_modal"
      post :move_after, to: "gantt#move_after"
      post :make_children, to: "gantt#make_children"
      post :color_rows, to: "gantt#color_rows"
      resources :baseline, only: %i[create destroy] do
        member do
          get :index, to: "gantt#index"
          post :renew_dates
        end
      end
    end
  end
end
resources :gantt