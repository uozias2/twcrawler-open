class GetTweetsProcessor
  @queue = :get_tweets
  def self.perform(session, num)
    begin
      p "background running"
      TwitterDatum.init3(session, num)
      TwitterDatum.getTweetsForExperiment
    rescue => exc
      p exc
    end
  end
end