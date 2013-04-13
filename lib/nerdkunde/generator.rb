require 'slim'
require 'sass'
require 'redcarpet'
require 'ostruct'
require 'fileutils'
require 'html_truncator'
require 'json'
require 'gst-kitchen'

class Nerdkunde::Generator

  def generate
    print "Generating Website "
    index_page
    print "."
    episode_pages
    print "."
    markdown_files
    print "."
    sass_file
    print "."
    copy_assets
    print "."
    copy_plugins
    puts " done" 
  end

  def index_page
    env = Class.new do
      attr_accessor :podcast

      def episode_abstract(episode)
        renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
        summary = renderer.render(episode.summary)
        HTML_Truncator.truncate(summary, 30)
      end
    end.new

    env.podcast = Podcast.from_yaml("podcast.yml")
    c = Slim::Template.new("templates/content/index.slim", pretty: true).render(env)
    File.open("public/index.html", "w") do |f|
      f.write(layout.render {c})
    end
  end

  def episode_pages
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
    podcast = Podcast.from_yaml("podcast.yml")
    podcast.episodes.each_with_index do |episode|
      env = Class.new do
        attr_accessor :podcast, :episode, :description

        def chapter_helper(episode)
          chapters = []
          episode.chapters.each do |c|
            chapters << {
              'start' => c.start,
              'title' => c.title
            }
          end
          chapters.to_json
        end
      end.new

      env.podcast = podcast
      env.episode = episode
      env.description = renderer.render(episode.summary)

      c = Slim::Template.new("templates/content/episode.slim", pretty: true).render(env)
      File.open("public/nk#{"%04d" % episode.number}.html", "w") do |f|
        f.write(layout.render {c})
      end
    end
  end

  def markdown_files
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    Dir.glob("templates/content/*.markdown").each do |md|
      mdfile = File.open(md, "rb").read
      File.open(File.join("public", "#{File.basename(md, ".markdown")}.html"), "w") do |f|
        f.write(layout.render {renderer.render(mdfile)})
      end
    end
  end

  def layout
    Slim::Template.new("templates/content/layout.slim", pretty: true)
  end

  def sass_file
    template = File.read('templates/stylesheets/base.sass')
    load_paths = ["templates/stylesheets"]
    load_paths += find_in_plugins("stylesheets")
    p load_paths
    sass_engine = Sass::Engine.new(template, load_paths: load_paths)
    FileUtils.mkdir("public/stylesheets") unless File.exist?("public/stylesheets")
    File.open("public/stylesheets/base.css", "w") do |f|
      f.write sass_engine.render
    end
  end

  def copy_assets
    FileUtils.cp_r("templates/images", "public/")
  end

  def copy_plugins
    Dir.new("templates/plugins").each do |dir|
      next if dir == "." || dir == ".."
      path = File.join("templates/plugins", dir)
      if File.directory? path
        Dir.new(path).each do |d|
          next if d == "." || d == ".."
          FileUtils.cp_r(File.join(path, d), "public/")
        end
      end
    end
  end

  def find_in_plugins(path)
    paths = []
    Dir.new("templates/plugins").each do |dir|
      next if dir == "." || dir == ".."
      path = File.join("templates/plugins", dir, path)
      p path
      paths << path if File.exist? path
    end
    paths
  end

end
