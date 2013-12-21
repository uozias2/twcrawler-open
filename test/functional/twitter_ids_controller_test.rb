require 'test_helper'

class TwitterIdsControllerTest < ActionController::TestCase
  setup do
    @twitter_id = twitter_ids(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:twitter_ids)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create twitter_id" do
    assert_difference('TwitterId.count') do
      post :create, twitter_id: { id: @twitter_id.id, user: @twitter_id.user }
    end

    assert_redirected_to twitter_id_path(assigns(:twitter_id))
  end

  test "should show twitter_id" do
    get :show, id: @twitter_id
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @twitter_id
    assert_response :success
  end

  test "should update twitter_id" do
    put :update, id: @twitter_id, twitter_id: { id: @twitter_id.id, user: @twitter_id.user }
    assert_redirected_to twitter_id_path(assigns(:twitter_id))
  end

  test "should destroy twitter_id" do
    assert_difference('TwitterId.count', -1) do
      delete :destroy, id: @twitter_id
    end

    assert_redirected_to twitter_ids_path
  end
end
