require 'gst-kitchen'

class Nerdkunde < Thor

  desc "generate", "Generates the website"
  def generate
    puts "Generating..."
    feeds
  end

  desc "feed", "Generates the RSS feeds"
  def feeds
    puts "Generating RSS Feeds"
    Podcast.from_yaml("podcast.yml").render_all_feeds
  end

end
