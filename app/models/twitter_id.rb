require "date"

class TwitterId
  include Mongoid::Document
  field :user_id, type: String
  field :user, type: String
  field :owner_id, type: String
  field :relation, type: String
  field :followers_count, type: String
  #relationの定義
  #public streamからならpublic
  #followerならfollower
  #friendならfriend
  


  def self.init(client)
  	@@client = client
  end

  def self.init2(session)
    @@session = session
  end




  #単純にパブリックタイムラインからとってくるアクション
  def self.getIDs
  	tmpTime = DateTime.now 
  	pp tmpTime.to_s + ": start to get ids from public stream."
    num = 0
    begin
      @@client.sample do |tweet|
        id =  tweet.user.id
        #もしdbにないidだったら
        if not TwitterId.where(:user_id => id).count > 0 and not id.class.to_s == "Twitter::NullObject"
          twitter_id = TwitterId.new(:user_id => id, :relation => "public", :owner_id => "")
          twitter_id.save
        end
        
        if id.class.to_s != "Twitter::NullObject"
          num = num + 1
          pp num.to_s
        end
    	end
    rescue => error
    	  pp "error: " + error.to_s
    end until num > 10000

    tmpTime2 = DateTime.now 
    pp tmpTime2.to_s + ": " + num.to_s + " users'ids were saved. it took " + ((tmpTime2 - tmpTime)* 24 * 60 * 60).to_f.to_s + " second(s)."
    num #return
  end

  #実験用データ収集アクション
  def self.getIDsForExperiment
    raise "session is needed." if !@@session #sessionの初期化が必要
    @@rootNum = 300 #publicstreamから集める人数
    #@@leafNum = 29 #最初の10名をたどって見つける人数の1/10

    @@tnow = Time.now
    dnow =  DateTime.new( @@tnow.year, @@tnow.mon, @@tnow.day, @@tnow.hour, @@tnow.min, @@tnow.sec)
    amonthagod = dnow - 30
    @@amonthago = Time.mktime( amonthagod.year, amonthagod.mon, amonthagod.day, amonthagod.hour, amonthagod.min, amonthagod.sec)
    

    if TwitterId.where(:relation => "public").count < @@rootNum + 10 
      client = Client.create(@@session[:token], @@session[:secret], "streaming")
      self.getIDsForExperiment1(client) #idをちょっと多めに集める
    else
      pp "have enough public ids"
    end
    
    
    client = Client.create(@@session[:token], @@session[:secret])
    if TwitterId.where(:relation => "root").count < @@rootNum 
      self.getIDsForExperiment2(client) #相互フォローなどのチェック
    else
      pp "have enough root ids"
    end

    
    #if TwitterId.where(:relation => "leaf").count <  @@leafNum * 10
    #  self.getIDsForExperiment3(client) #深さ優先検索
    #end
  end


  #実験用データ収集アクション
  #処理1
  #ユーザidをpublic streamから収集する
  #実際に必要なのは人数より多めにとっておく
  def self.getIDsForExperiment1 (client)
    pp "test"
    
    planedNum = @@rootNum  + 10 #集めたい人数 
    num =  TwitterId.where(:relation => "public").count().to_i #集めた人数


    #最初の10名のユーザidを収集
    client.sample do |tweet|
      id = tweet.user.id
      #まだとっていない人であることを確認 and 空のtweetでない確認 and フォロワー1000人以下を確認
      if TwitterId.where(:user_id => id, :relation => "public").count == 0 and TwitterId.where(:user_id => id, :relation => "root").count == 0 and id.class.to_s != "Twitter::NullObject" and tweet.user.protected != "true" and tweet.user.followers_count.to_i < 1001 and tweet.user.followers_count.to_i > 0


        twitter_id = TwitterId.new(:user_id => id, :relation => "public", :user => tweet.user.to_hash,  :owner_id => "", :followers_count => tweet.user.followers_count)
        twitter_id.save
        num +=  1 
        pp id.to_s + " heve been saved. total " + num.to_s + " ." #for debug
              
  
      end 
      break if num >= planedNum #予定人数があつまったらループを抜ける
    end 

  end

  #実験用データ収集アクション
  #処理2
  #あつめた人たちが、相互にフォローしてないことをチェックする
  #あと、その人のuser_timeline中で一番新しいのが1ヶ月以内であることをチェックする　←考えたら、これは当たり前だった
  def self.getIDsForExperiment2 (client)
    checkedNum = TwitterId.where(:relation => "root").count().to_i

    finished = false
    begin
      begin
        users = TwitterId.where(:relation => "public")
        users.each do |user|
          mutualFlg = self.isMutualFollower(client, user.user_id) #相互フォローしてない
          if not mutualFlg 
            checkedNum += 1 
            TwitterId.where(:user_id => user.user_id).first.update_attributes(:relation => "root")
          end    
          if checkedNum >= @@rootNum 
            finished = true
            break
          end
        end 
      rescue => e
        if e.class.to_s == "Moped::Errors::CursorNotFound"
          pp "cursor timeout"
        end 
      end
    end until finished

    TwitterId.where(:relation => "public").delete #いらん人は削除

  end


  #フォローしてないことをチェック
  def self.isMutualFollower(client, id)
    result = false
    gotFowllowers = false
    gotFriends = false

    #フォロワーを登録していき、かぶったらfalse
    begin 
      options = {count =>5000}
      if defined? followers
        options[:cursor] = followers.next_cursor
      end

      begin

        #followers = client.follower_ids(id.to_i, options)
        followers = Client.callApi(client, "follower_ids", id.to_i, options)
      rescue => e
        #とりあえず、ありとあらゆるエラーはスルーすることにした
        #raise e
        pp e.class.to_s
        result = true
        break   
      end

      if result
        break
      end

      pp followers.count.to_s + " followers are found."#for debug

      followers.each do |follower|
        #rootの中にいなければオK
        if TwitterId.where(:user_id => follower, :relation => "root").count == 0
          values = {
            :user_id => follower,
            :relation => "follower",
            :owner_id => id.to_s
          }
          twitter_id = TwitterId.new(values)
          twitter_id.save

        else
          result = true
          pp id.to_s + "'s folower " + follower.to_s + " was already saved."
          #今までに登録したこのユーザのフォロワーを消す
          TwitterId.where(:owner_id => id.to_s).delete
        end
        if result
          break
        end

      end
      if result
        break
      end
    end until followers.next_cursor == 0 
   
    #フレンドを登録していき、かぶったらfalse
    if not result #フォロワーがかぶってたら実行しない
      begin 
        options = {count =>5000}
        if defined? friends
          options[:cursor] = friends.next_cursor
        end

      
        begin
          #friends = client.friend_ids(id.to_i,  options) 
          friends = Client.callApi(client, "friend_ids", id.to_i, options)
        rescue => e
          #raise e
          pp e.class.to_s
          result = true
          break  
        end
        if result
          break
        end

        pp friends.count.to_s + " friends are found."#for debug

        friends.each do |friend|
          if TwitterId.where(:user_id => friend, :relation => "root").count == 0
             values = {
              :user_id => friend,
              :relation => "friend",
              :owner_id => id.to_s
            }
            twitter_id = TwitterId.new(values)
            twitter_id.save

          else
            result = true
            pp id.to_s + "'s friend " + friend.to_s + " was already saved."

            #今までに登録したこのユーザのフレンドを消す
            TwitterId.where(:owner_id => id.to_s).delete
          end

          if result
            break
          end
        end
        if result
          break
        end
      end until friends.next_cursor == 0
    end

    pp id.to_s + " is a mutal follower? " + result.to_s
    result #return
  end


  #user_timelineの一番最初が一ヶ月以内であることを確認
  def self.checkJoiningForAMonth(client, user, amonthago)
    result = false
    options = {:count => 2}
    tweets = client.user_timeline(user.user_id.to_i, options)
    if tweets.count > 0
      created = tweets[0].created_at
      pp "created in " + created.to_s 
      if created > amonthago
        result = true
        pp user.user_id.to_s +  " is ok."
      end 
    end 
    result #return
  end


  #実験用データ収集アクション
  #処理3
  #次に、それぞれを深さ優先で各ユーザを起点に29名ずつ、合計300人あつまるまで続ける
  #ただし、user_timelineを参照して一番新しいのが1ヶ月より前の人ははぶく
  #1000人よりおおいフォロワーがいる人もはぶく
  #プロテクトされてる人も
  def self.getIDsForExperiment3(client)


    num = 0 #集めた人数

    rootUsers = TwitterId.where(:relation => "root")

    rootUsers.each do |rootUser|
      getAFollower(rootUser.user_id, num, client)
    end
    pp rootUser.user_id.to_s + "'s follwer  ' "

  end

  #再起的に呼び出してidを保存していく
  def self.getAFollower(id, num, client)
    #todo エラー処理
    usersGot = false
    options = {:count => 200}
    next_user_id = 0 #初期化
    begin
      if defined? users 
        if users.next_cursor != 0
         options[:cursor] = users.next_cursor
        end
      end
      begin
        begin
          usersGot = false
          users = client.followers(id.to_i, options)
          usersGot = true
        rescue => e
          if e.class.to_s == "Twitter::Error::TooManyRequests"
            #raise e 
            pp e.class.to_s
            sleep(900) #15分待つ   
          else
            return false
          end
        end

      end until usersGot == true #usersが取得できるまでやる
      i = Random.rand(100)
      #todo iから200までで見つからなかったらどうすんの
      j = 0
      users.each do |user|
        j += 1
        if j > i 
          pp user.id.to_s + "/ protected:" + user.protected.to_s + " followers_count:" + user.followers_count.to_s 
          if user.protected != "true" and user.followers_count < 1001 and TwitterId.where(:user_id => user.id, :relation => "root").count() == 0 and TwitterId.where(:user_id => user.id, :relation => "leaf").count() == 0
            num += 1
          
            twitter_id = TwitterId.new(:user_id => user.id, :relation => "leaf", :user => Oj.dump(user, :mode => :compat),  :owner_id => "", :followers_count => user.followers_count)
            twitter_id.save
            pp "leaf #" + num.to_s + " " + user.id.to_s + " is saved."
            next_user_id = user.id

            if num > @@leafNum
              return
            else
              pp "j:" + j.to_s+ "/next_user_id:" + next_user_id.to_s
              if self.getAFollower(next_user_id, num, client) #再起呼び出し
                break;
              else
                #エラーがでてとまったら
                "child process failed!"
                self.getAFollower(id, num, client) #この階層でやりなおす
              end
            end          
          end
        end
      end
      #次のユーザが見つかったらブレーク
      if next_user_id != 0
        break;
      end
    end until users.next_cursor == 0 
    return true
  end


  #特定ユーザのフォロワー
  def self.getFollowers(id)
    self.getUserIDs(id, "follower")
  end

  #特定ユーザのフレンド　
  def self.getFriends(id)
    self.getUserIDs(id, "friend")
  end

=begin  
  def self.getFollowers(id)
  	tmpTime = DateTime.now
  	pp tmpTime.to_s + ": start to get followers'ids."

  	if id
  		tareget_id = id
  	else
  		tareget_id = @@client.current_user.id
  	end

    #followers = @client.followers(@id)
    options = {count =>5000}

    #ページングする
    num = 0
    begin
      if defined? followers 
        if followers.next_cursor != -1
         options[:cursor] = followers.next_cursor
        end
      end
      begin
        followers = @@client.follower_ids(tareget_id.to_i, options)

        followers.each do |follower|

      		#tweet2 = Oj.load(tweetJ, :mode => :compat)

      		values = {
        		:user_id => follower,
            :relation => "follower",
            :owner_id => tareget_id.to_s
      		}

      		twitter_id = TwitterId.new(values)
          if twitter_id.save 
            num = num + 1
          end
        end

      rescue => e
        #エラー処理
        if e.class.to_s == "Twitter::Error::TooManyRequests"
          #15分待つ
          pp "waiting..."
          sleep(900)   
        end      
      end

    end while followers.next_cursor != -1 

    tmpTime2 = DateTime.now 
    pp tmpTime2.to_s + ": " + num.to_s + " friends'ids were saved. it took " + ((tmpTime2 - tmpTime)* 24 * 60 * 60).to_f.to_s + " second(s)."
    num #return
  	
  end
=end

=begin
  def self.getFriends(id)
    tmpTime = DateTime.now
    pp tmpTime.to_s + ": start to get friends' ids."    

    if id
      target_id = id.to_i
      #target_id = 96952332
    else
      target_id = @@client.current_user.id.to_i
    end


    friends = @@client.friend_ids(target_id,  :count => 5000)

    num = 0
    friends.each do |friend|

      values = {
        :user_id => friend,
        :relation => "friend",
        :owner_id => target_id.to_s
      }

      twitter_id = TwitterId.new(values)

      if twitter_id.save 
        num = num + 1
      end

    end


    tmpTime2 = DateTime.now 
    pp tmpTime2.to_s + ": " + num.to_s + " friends'ids were saved. it took " + ((tmpTime2 - tmpTime)* 24 * 60 * 60).to_f.to_s + " second(s)."
    num #return
  end
=end


  def self.getUserIDs(id, target)
    tmpTime = DateTime.now
    pp tmpTime.to_s + ": start to get "+target+"s'ids."

    if id
      target_id = id
    else
      target_id = @@client.current_user.id
    end

    #followers = @client.followers(@id)
    options = {count =>5000}

    #ページングする
    num = 0
    begin
      if defined? users 
        if users.next_cursor != 0
         options[:cursor] = users.next_cursor
        end
      end
      begin
        case target
        when "follower"
          users = Client.callApi(client, "follower_ids", target_id.to_i, options)
          #users = @@client.follower_ids(target_id.to_i, options)
        when "friend"
          users = Client.callApi(client, "friend_ids", target_id.to_i, options)
          #users = @@client.friend_ids(target_id.to_i,  options)     
        end

        users.each do |user|

          values = {
            :user_id => user,
            :relation => target,
            :owner_id => target_id.to_s
          }

          twitter_id = TwitterId.new(values)
          if twitter_id.save 
            num = num + 1
          end
          #end
          
        end

      rescue => e
        #エラー処理
        if e.class.to_s == "Moped::Errors::CursorNotFound"
          pp "cursor timeout"
        else 
          raise e
        end
      end

      if defined? users.next_cursor
        pp "cursor" + users.next_cursor.to_s #for debug
      end
      if defined? users.count
        pp "count" + users.count.to_s
      end 

  
    end until users.next_cursor == 0 #取得できるうちは取得する 

    tmpTime2 = DateTime.now 
    pp tmpTime2.to_s + ": " + num.to_s + " " + target +"'s ids were saved. it took " + ((tmpTime2 - tmpTime)* 24 * 60 * 60).to_f.to_s + " second(s)."
    num #return

  end


end
