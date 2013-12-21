class GetIdsProcessor
  @queue = :get_ids
  def self.perform(session)
    begin
      p "background running"

      client = Client.create(session[:token], session[:secret], "streaming")
      TwitterId.init(client)
      num = TwitterId.getIDs

      p num
    rescue => exc
      p exc
    end
  end
end