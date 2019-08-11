Rails.application.routes.draw do
  get 'mainpage/index', as: :index
  # get 'mainpage/index/:day_shift', to: "mainpage#index", as: :mainpage_index_p
  root 'mainpage#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
