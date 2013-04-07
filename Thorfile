$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

require 'gst-kitchen'
require 'nerdkunde'

class Nerdkunde < Thor

  desc "generate", "Generates the website"
  def generate
    puts "Generating..."
    feeds
    website
  end

  desc "feed", "Generates the RSS feeds"
  def feeds
    puts "Generating RSS Feeds"
    Podcast.from_yaml("podcast.yml").render_all_feeds
  end

  desc "website", "Generates the Website"
  def website
    ::Nerdkunde::Generator.new.generate
  end

end
