class TwitterDatum
  include Mongoid::Document
  field :id, type: String
  field :user_id, type: String
  field :retweeted, type: String
  field :favorited, type: String
  field :in_reply, type: String
  field :retweet_count, type: String
  field :tweet

  #初期化メソッド
  def self.init(client)
  	@@client = client
  end

  def self.init2(session)
    @@session = session
  end


  def self.init3(session, num)
    @@session = session
    @@targetInThisServer = num.to_i
  end

  #あるユーザのフォロワー、フレンド、そのユーザのuser_timelineをすべて取得
  def self.getAll(id)
    #自分のツイート取得
    self.getTweet(id)

    #フォロワー取得
    TwitterId.init(@@client)
    TwitterId.getFollowers(id)

    #フォロワーのツイート取得
    followers = TwitterId.where(:relation => "follower", :owner_id => id)
    followers.each do |follower|
      self.getTweet(follower.user_id)
    end

    #フレンド取得
    TwitterId.getFriends(id)

    #フレンドのツイート取得
    friends = TwitterId.where(:relation => "friend", :owner_id => id)
    friends.each do |friend|
      self.getTweet(friend.user_id)
    end
  end



  def self.getTweet(id)

  	if id
      target_id = id.to_i
      #target_id = 96952332
    else
      target_id = @@client.current_user.id.to_i
    end

  	tmpTime = DateTime.now 
  	pp tmpTime.to_s + ": start to get tweets from " + target_id.to_s + "'s user_timeline"

  	options = {:count => 200}
    max_id = -1
    num = 0
    begin  	
      begin
        
        if max_id != -1
          max_id = max_id -1
          options[:max_id] = max_id
        end

        pp "max_id: " + options[:max_id].to_s #for debug

        tweets = Client.callApi(client, "user_timeline", target_id.to_i, options) #エラー処理
        #tweets = @@client.user_timeline(target_id, options)
        
        max_id = tweets.last.id
        
        pp "count: " + tweets.count.to_s #for debug
        pp "first: " + tweets.first.id.to_s #for debug

        tweets.each do |tweet|


      		#tweet2 = Oj.load(tweetJ, :mode => :compat)


      		in_reply = tweet["in_reply_to_user_id"].to_s

      		values = {
            :tweet_id =>  tweet.id,
        		:user_id=> tweet.user.id.to_s,
        		:retweeted => tweet.retweeted,
        		:favorited => tweet.favorited,
        		:in_reply => in_reply,
        		:retweet_count => tweet.retweet_count,
        		:tweet => Oj.dump(tweet, :mode => :compat)
      		}

   
          #同じツイートが無ければ
          if TwitterDatum.where(:id => tweet.id).count == 0
        		twitter_datum = TwitterDatum.new(values)
        		if twitter_datum.save 
        			num = num + 1
            else
              pp "save failed"
        		end
          else 
            pp "same tweet is found."
          end 

        end
      rescue => e
        #エラー処理
        if e.class.to_s == "Moped::Errors::CursorNotFound"
          pp "cursor timeout"
        else
          raise e
        end         
      end 

      pp "num: " + num.to_s #for debug
      pp "count: " + tweets.count.to_s

    end until tweets.count == 0

    tmpTime2 = DateTime.now 
    pp tmpTime2.to_s + ": " + num.to_s + " tweets were saved. it took " + ((tmpTime2 - tmpTime)* 24 * 60 * 60).to_f.to_s + " second(s)."
    num #return
    
  end

  #実験用にツイートを集める
  def self.getTweetsForExperiment

    @@tnow = Time.now
    dnow =  DateTime.new( @@tnow.year, @@tnow.mon, @@tnow.day, @@tnow.hour, @@tnow.min, @@tnow.sec)
    amonthagod = dnow - 30
    @@amonthago = Time.mktime( amonthagod.year, amonthagod.mon, amonthagod.day, amonthagod.hour, amonthagod.min, amonthagod.sec)

    rootUsers = TwitterId.where(:relation => "root")

    @@client = Client.create(@@session[:token], @@session[:secret])
    
    if @@targetInThisServer
      
    else
      @@targetInThisServer = 1
    end
    count = 0
    finishedCount = 0

    #300人のそれぞれについて
    rootUsers.each do |rootUser|

      count += 1
      pp "root user #" + count.to_s
      #このサーバの対象外だったら
      if @@targetInThisServer > count
        "is not target user in this server"
        next;
      end

      #30名分終わったら
      if finishedCount >= 30
        pp "finished!"
        break;
      end

      #自分
      getTweetsForAMonth(rootUser.user_id)

      #フォロワーは1000人以内だし、フレンドも5000人以内と考える
      #フォロワー
      followerIds = Client.callApi(@@client, "follower_ids", rootUser.user_id, {"count" =>5000})
      
      #鍵付きユーザが混入してたらとばす 
      if followerIds.nil?
        pp "protected user:" + rootUser.to_s
        break
      end
      followerIds.each do |folowerId|

        twitter_id = TwitterId.new(:user_id => folowerId, :relation => "follower", :user => "",  :owner_id => rootUser.user_id, :followers_count => "")
        twitter_id.save

        getTweetsForAMonth(folowerId)
      end
        
      #フレンド
      friendIds = Client.callApi(@@client, "friend_ids", rootUser.user_id, {"count" =>5000})
      #鍵付きユーザが混入してたらとばす 
      if friendIds.nil?
        pp "protected user:" + rootUser.to_s
        break
      end
      friendIds.each do |friendId|

        twitter_id = TwitterId.new(:user_id => friendId, :relation => "friend", :user => "",  :owner_id => rootUser.user_id, :followers_count => "")
        twitter_id.save

        getTweetsForAMonth(friendId)


      end


      #全部終わったユーザはrootからはずす
      TwitterId.where(:user_id => rootUser.user_id).first.update_attributes(:relation => "finished")
      finishedCount += 1
    end
    



  end

  #実験用にツイートを集める
  #処理1 
  def self.getTweetsForAMonth(id)

    if id
      target_id = id.to_i
      #target_id = 96952332
    else
      raise "id is not set"
    end

    tmpTime = DateTime.now 
    pp tmpTime.to_s + ": start to get tweets from " + target_id.to_s + "'s user_timeline"

    options = {:count => 200}
    max_id = -1
    num = 0

    finished = false

    begin   
      begin
        
        if max_id != -1
          max_id = max_id -1
          options[:max_id] = max_id
        end

        pp "max_id: " + options[:max_id].to_s #for debug
        
        #tweets = @@client.user_timeline(target_id, options)
        tweets = Client.callApi(@@client, "user_timeline", target_id, options)
        
        #もしnilがかえってきたら、一人分とばす
        if tweets.nil?
          finished = true
          break
        end
        

        max_id = tweets.last.id
        
        pp "count: " + tweets.count.to_s #for debug
        pp "first: " + tweets.first.id.to_s #for debug

        tweets.each do |tweet|


          in_reply = tweet["in_reply_to_user_id"].to_s

          values = {
            :tweet_id =>  tweet.id,
            :user_id=> tweet.user.id.to_s,
            :retweeted => tweet.retweeted,
            :favorited => tweet.favorited,
            :in_reply => in_reply,
            :retweet_count => tweet.retweet_count,
            #:tweet => Oj.dump(tweet, :mode => :compat)
            :tweet => tweet.to_hash
            #:tweet => tweet.to_json
          }



    
          #同じツイートが無ければ
          if TwitterDatum.where(:id => tweet.id).count == 0
            twitter_datum = TwitterDatum.new(values)
            if twitter_datum.save 
              num = num + 1
            else
              pp "save failed"
            end
          else 
            pp "same tweet is found."
          end 

          #一ヶ月より前のツイートだったらブレーク
          if tweet.created_at <= @@amonthago
            finished = true
            break
          end

        end
      rescue => e
  
        #エラーが出てもログだけだしてつづける
        pp e.to_s

      end 

      pp "num: " + num.to_s #for debug
      
      #もし終了していたら
      if finished 
        break
      end
      if tweets.nil?
        break
      end
    end until tweets.count == 0

    tmpTime2 = DateTime.now 
    pp tmpTime2.to_s + ": " + num.to_s + " tweets were saved. it took " + ((tmpTime2 - tmpTime)* 24 * 60 * 60).to_f.to_s + " second(s)."
    num #return
    
  end
end
