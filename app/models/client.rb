class Client

  @@ids = [{'consumer_key' => 'key', 'consumer_secret' =>'secret'  }]
  @@counter = 0


  #rate limit管理用
  @@lastExecuteFriendIds = Time.new
  @@lastExecuteFollowerIds = Time.new
  @@lastExecuteUserTimeline = Time.new

  #APIたたくときのエラー処理をしてくれる関数
  #つくりかけ
  def self.callApi(client, actionName, id, options)

    sleepTIme = 0 #何秒やすむか
    lastExecute = 0
    begin 
      begin
        case actionName
        when "friend_ids"
          lastExecute = @@lastExecuteFriendIds.clone
          @@lastExecuteFriendIds = Time.now
          retVal = client.friend_ids(id.to_i, options)
        when "follower_ids"
          lastExecute = @@lastExecuteFollowerIds.clone
          @@lastExecuteFollowerIds = Time.now
          retVal = client.follower_ids(id.to_i, options)
        when "user_timeline"
          lastExecute = @@lastExecuteUserTimeline.clone
          @@lastExecuteUserTimeline = Time.now
          retVal = client.user_timeline(id.to_i, options)
        else
          lastExecute = Time.now   
          pp "invalid actionName"
        end
      rescue => e
        if e.class.to_s == "Twitter::Error::TooManyRequests"
          pp "last execution: " + lastExecute.to_s
          if lastExecute == 0
            sleepTime = 900 
          else
            sleepTime = 900 - (Time.now - lastExecute).to_i
          end
          if sleepTime < 0
            sleepTime = 900
          end
          #15分から、最後に実行した時からの差を調べる
          pp "sleep " + sleepTime.to_s + "seconds"
          sleep(sleepTime.to_i)
        elsif e.class.to_s == "Twitter::Error::Unauthorized"
          #unauthorized おそらく鍵付きユーザの場合は無視
          p "protected user:" + id.to_s
          return nil
        elsif e.class.to_s = "Twitter::Error"
          p "error:" + e.class.to_s 
        else
          #他のエラーは処理しない
          raise e
        end
      rescue Timeout::Error => e
        p "error:" + e.class.to_s 
        #タイムアウトは特別
      end
    end until not retVal.nil?
    return retVal
  end

  #なぜかクラス関数じゃないとうごくクライアントが返せない
  def self.make(token, secret)
    retVal = Twitter::REST::Client.new do |config|
      config.consumer_key        = @@ids[@@counter]['consumer_key']
      config.consumer_secret     = @@ids[@@counter]['consumer_secret']      
      #config.consumer_key        = 'ZThh7appkK6zIYP6fkhXJA'
      #config.consumer_secret     = 'JWRWmtXIOnHWpWZiTykVaZrn2rEVVSwdKRpMo6dTI'
      config.access_token        = token
      config.access_token_secret = secret
    end
    #pp retVal
    retVal
  end
  
  #ファクトリメソッド
  def self.create(token, secret, target='REST')
    @token = token
    @secret = secret
    change target
  end
  
  #実際のアカウント作成と切り替え
  def self.change(target)
    case target
    when 'streaming'
      retVal = Twitter::Streaming::Client.new do |config|
        config.consumer_key        = @@ids[@@counter]['consumer_key']
        config.consumer_secret     = @@ids[@@counter]['consumer_secret']
        config.access_token        = @token
        config.access_token_secret = @secret    
      end
    else
      #ディフォルトでRESTAPI
      retVal = Twitter::REST::Client.new do |config|
        #pp @@ids[@@counter]['consumer_key']
        #pp @@ids[@@counter]['consumer_secret']

        config.consumer_key        = @@ids[@@counter]['consumer_key']
        config.consumer_secret     = @@ids[@@counter]['consumer_secret']
        config.access_token        = @token
        config.access_token_secret = @secret
      end 
    end
    #@@counter = @@counter + 1  #idを切り替えても意味ない
    #if @@counter + 1> @@ids.length
    #  @@counter = 0
    #end 
    pp "user" + @@counter.to_s
    retVal
  end



end
