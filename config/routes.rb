Rails.application.routes.draw do
  root 'items#index'
  resources :items do
    collection do
      get 'done'
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
