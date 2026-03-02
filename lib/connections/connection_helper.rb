require "faraday"

class Connections::ConnectionHelper
  def self.pwhl_connection
    @connection ||= Faraday.new("https://lscluster.hockeytech.com/feed/index.php") do |c|
      c.params[:key] = "446521baf8c38984"
      c.params[:client_code] = "pwhl"
    end
  end
end
