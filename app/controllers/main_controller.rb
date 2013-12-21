require 'pp'

class MainController < ApplicationController
  def index
  end

  #試験用のアクション
  def test
    render json: "test"
  end
  
  #非同期処理用のアクション	

  def getTweetsAsync
    if params[:num]
      num = params[:num]
    else
      num = 1
    end

  	Resque.enqueue(GetTweetsProcessor, session, num)
  	render text: "ok"
  	

  end

  def getIDsAsync
  	Resque.enqueue(GetIdsProcessor, session)
  	render text: "ok"
  end



end
