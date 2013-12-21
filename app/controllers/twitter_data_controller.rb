# -*- coding: utf-8 -*
require 'pp'

class TwitterDataController < ApplicationController
  # GET /twitter_data
  # GET /twitter_data.json
  def index
    @twitter_data = TwitterDatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @twitter_data }
    end
  end

  # GET /twitter_data/1
  # GET /twitter_data/1.json
  def show
    @twitter_datum = TwitterDatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @twitter_datum }
    end
  end


  # DELETE /twitter_data/1
  # DELETE /twitter_data/1.json
  def destroy
    @twitter_datum = TwitterDatum.find(params[:id])
    @twitter_datum.destroy

    respond_to do |format|
      format.html { redirect_to twitter_data_url }
      format.json { head :no_content }
    end
  end
  
  #結果をクリアする
  def clear
    conn = Mongo::Connection.new
    db = conn.db("twcrawler2_development")
    collection = db.collection("twitter_data")
    result = collection.remove();
    if result
      render text: "ok"
    else
      render text: "no"
    end 
  end

  def count
    render text: TwitterDatum.count()
  end

  #tweet取得用
  def getTweet

    if params[:id]
      id = params[:id]
    end

    if params[:max_id]
      max_id = params[:max_id]
    end

    @client = Client.create(session[:token], session[:secret])
    TwitterDatum.init(@client)
    num = TwitterDatum.getTweet(id)

    render json: num 
  end

    #実験用にツイート集める
  def getTweetsForExperiment

    if params[:num]
      num = params[:num]
    else
      num = 1
    end
    TwitterDatum.init3(session, num)
    TwitterDatum.getTweetsForExperiment()
    render text: "done"

  end

end
