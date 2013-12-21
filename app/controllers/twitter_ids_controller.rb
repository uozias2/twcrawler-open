
require 'pp'
class TwitterIdsController < ApplicationController
  # GET /twitter_ids
  # GET /twitter_ids.json
  def index
    @twitter_ids = TwitterId.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @twitter_ids }
    end
  end

  def clear
    conn = Mongo::Connection.new
    db = conn.db("twcrawler2_development")
    collection = db.collection("twitter_ids")
    result = collection.remove();
    if result
      render text: "ok"
    else
      render text: "no"
    end
  end

  # GET /twitter_ids/1
  # GET /twitter_ids/1.json
  def show
    @twitter_id = TwitterId.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @twitter_id }
    end
  end

  def count
    render text: TwitterId.count()
  end


  #public streamsからユーザidを収集する
  def getIDs

    @client = Client.create(session[:token], session[:secret], "streaming")
    TwitterId.init(@client)
    num = TwitterId.getIDs
    render text: num
    
  end

  #ユーザのフォロワーを取得する
  #引数 id 取得したいユーザのid
  def getFollowers

    @client = Client.create(session[:token], session[:secret])

    if params[:id]
      id = params[:id]
    else
      
    end
    
    TwitterId.init(@client)
    num = TwitterId.getFollowers(id)

    render text: num
  end

  #そのユーザがフォローしている人たちのidを取得
  def getFriends
    @client = Client.create(session[:token], session[:secret])

    if params[:id]
      id = params[:id]
    end  
    
    TwitterId.init(@client)
    num = TwitterId.getFriends(id)

    render text: num

  end


  #実験用にデータ集める
  def getIDsForExperiment

    TwitterId.init2(session)
    TwitterId.getIDsForExperiment()

    render text: "done"
  end





  # DELETE /twitter_ids/1
  # DELETE /twitter_ids/1.json
  def destroy
    @twitter_id = TwitterId.find(params[:id])
    @twitter_id.destroy

    respond_to do |format|
      format.html { redirect_to twitter_ids_url }
      format.json { head :no_content }
    end
  end
end
