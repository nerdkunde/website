require 'slim'
require 'sass'
require 'redcarpet'
require 'ostruct'

require 'gst-kitchen'

class Nerdkunde::Generator

  def generate
    puts "Generating Website"
    index_page
    episode_pages
    markdown_files
    sass_file
  end

  def index_page
    env = OpenStruct.new(
      podcast: Podcast.from_yaml("podcast.yml")
    )
    c = Slim::Template.new("templates/slim/index.slim", pretty: true).render(env)
    File.open("public/index.html", "w") do |f|
      f.write(layout.render {c})
    end
  end

  def episode_pages
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
    podcast = Podcast.from_yaml("podcast.yml")
    podcast.episodes.each_with_index do |episode, index|
      env = OpenStruct.new(
        podcast: podcast,
        episode: episode,
        description: renderer.render(episode.summary)
      )
      c = Slim::Template.new("templates/slim/episode.slim", pretty: true).render(env)
      File.open("public/nk#{"%04d" % index}.html", "w") do |f|
        f.write(layout.render {c})
      end
    end
  end

  def markdown_files
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    Dir.glob("templates/slim/*.markdown").each do |md|
      mdfile = File.open(md, "rb").read
      File.open(File.join("public", "#{File.basename(md, ".markdown")}.html"), "w") do |f|
        f.write(layout.render {renderer.render(mdfile)})
      end
    end
  end

  def layout
    Slim::Template.new("templates/slim/layout.slim", pretty: true)
  end

  def sass_file
    template = File.read('templates/sass/base.sass')
    sass_engine = Sass::Engine.new(template)
    File.open("public/stylesheets/base.css", "w") do |f|
      f.write sass_engine.render
    end
  end

end
