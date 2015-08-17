%w( rubygems rest_client json nokogiri redis ).each{ |lib| require lib }
%w( caching common reddit ).each{ |file| load File.expand_path( File.join( File.dirname( __FILE__ ), "share_counts", "#{file}.rb" ) ) } # TODO: replace load with require

module ShareCounts

  extend Common
  extend Caching

  def self.extract_count *args
    extract_info *args
  end

  def self.supported_networks
    %w(twitter facebook linkedin stumbleupon tumblr)
  end
  
  def self.reddit url, raise_exceptions = false
    try("reddit", url, raise_exceptions) {
      extract_count from_json("http://www.reddit.com/api/info.json", :url => url ), 
        :selector => "data/children/data/score" 
    }
  end
  
  def self.reddit_with_permalink url, raise_exceptions = false
    ShareCounts::Reddit.info_for url, raise_exceptions
  end
  
  def self.digg url, raise_exceptions = false
    try("digg", url, raise_exceptions) {
      extract_count from_json("http://services.digg.com/2.0/story.getInfo", :links => url ), 
        :selector => "stories/diggs"
    }
  end

  def self.twitter url, raise_exceptions = false
    try("twitter", url, raise_exceptions) {
      extract_count from_json("http://urls.api.twitter.com/1/urls/count.json", :url => url), 
        :selector => "count"
    }
  end

  # https://graph.facebook.com/fql?q=SELECT%20like_count,%20total_count,%20share_count,%20click_count,%20comment_count%20FROM%20link_stat%20WHERE%20url%20=%20%22http://sevenly.org/FightForHer%22
  def self.facebook url, raise_exceptions = false
    try("facebook", url, raise_exceptions) {
      extract_count from_json("https://graph.facebook.com/fql", :q => %{SELECT share_count FROM link_stat WHERE url="#{url}"}), 
      :selector => "data/share_count"
    }
  end

  def self.linkedin url, raise_exceptions = false 
    try("linkedin", url, raise_exceptions) {
      extract_count from_json("http://www.linkedin.com/countserv/count/share", 
        :url => url, :format => 'json'), :selector => "count"
    }
  end

  def self.googlebuzz url, raise_exceptions = false 
    try("googlebuzz", url, raise_exceptions) {
      from_json("http://www.google.com/buzz/api/buzzThis/buzzCounter", 
        :url => url, :callback => "google_buzz_set_count" )[url]
    }
  end

  def self.stumbleupon url, raise_exceptions = false 
    try("stumbleupon", url, raise_exceptions) {
      Nokogiri::HTML.parse( 
          make_request("http://www.stumbleupon.com/badge/embed/5/", :url => url ) 
        ).xpath( "//body/div/ul/li[2]/a/span").text.to_i
    }
  end

  def self.tumblr url, raise_exceptions = false
    try("tumblr", url, raise_exceptions) {
      extract_count from_json("http://api.tumblr.com/v2/share/stats", :url => url), 
        :selector => "response/note_count"
    }
  end

  def self.all url
    supported_networks.inject({}) { |r, c| r[c.to_sym] = ShareCounts.send(c, url); r }
  end
  
  def self.selected url, selections
    selections.map{|name| name.downcase}.select{|name| supported_networks.include? name.to_s}.inject({}) {
       |r, c| r[c.to_sym] = ShareCounts.send(c, url); r }
  end
end