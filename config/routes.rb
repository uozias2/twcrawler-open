Twcrawler2::Application.routes.draw do
 root :to => 'main#index'

  
  get "twitter_ids/clear"
  get "twitter_ids/count"
  get "twitter_ids/getFollowers"
  get "twitter_ids/getFriends"
  get "twitter_ids/getIDs"
  get "twitter_ids/getIDsForExperiment"
  match "twitter_ids/:id", :to => "twitter_ids#destroy", :via => :delete
  get "twitter_ids/index", :as => :twitter_ids 
  match "twitter_ids/:id", :to => "twitter_ids#show", :as => :twitter_id


  get "twitter_data/clear"
  get "twitter_data/count"
  get "twitter_data/getTweet"
  get "twitter_data/getTweetsForExperiment"
  match "twitter_data/:id", :to => "twitter_data#destroy", :via => :delete
  get "twitter_data/index", :as => :twitter_data 
  match "twitter_data/:id", :to => "twitter_data#show", :as => :twitter_datum

 
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_user_session
    get 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end

  get "main/getTweetsAsync"
  get "main/getIDsAsync"
  get "main/getFollowersAsync"
  get "main/getFriendsAsync"

  mount Resque::Server, at: "/resque"

  #OmniAuth
  #match "/auth/:provider/callback" => "sessions#callback"
  #match "/logout" => "sessions#destroy", :as => :logout

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end