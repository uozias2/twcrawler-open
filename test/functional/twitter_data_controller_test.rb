require 'test_helper'

class TwitterDataControllerTest < ActionController::TestCase
  setup do
    @twitter_datum = twitter_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:twitter_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create twitter_datum" do
    assert_difference('TwitterDatum.count') do
      post :create, twitter_datum: { favorited: @twitter_datum.favorited, in_reqply: @twitter_datum.in_reqply, retweeted: @twitter_datum.retweeted, tweet: @twitter_datum.tweet, user_id: @twitter_datum.user_id }
    end

    assert_redirected_to twitter_datum_path(assigns(:twitter_datum))
  end

  test "should show twitter_datum" do
    get :show, id: @twitter_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @twitter_datum
    assert_response :success
  end

  test "should update twitter_datum" do
    put :update, id: @twitter_datum, twitter_datum: { favorited: @twitter_datum.favorited, in_reqply: @twitter_datum.in_reqply, retweeted: @twitter_datum.retweeted, tweet: @twitter_datum.tweet, user_id: @twitter_datum.user_id }
    assert_redirected_to twitter_datum_path(assigns(:twitter_datum))
  end

  test "should destroy twitter_datum" do
    assert_difference('TwitterDatum.count', -1) do
      delete :destroy, id: @twitter_datum
    end

    assert_redirected_to twitter_data_path
  end
end
