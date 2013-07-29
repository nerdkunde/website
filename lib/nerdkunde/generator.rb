#encoding: utf-8

require 'slim'
require 'sass'
require 'redcarpet'
require 'ostruct'
require 'fileutils'
require 'html_truncator'
require 'json'
require 'gst-kitchen'

class Nerdkunde::Generator

  SUBTITLES = [
      "Jetzt geht's los. Bodo, Klaus, Lucas und Tobi reden in der nullten Ausgabe der Nerdkunde über ToDo Listen, Application Launcher, Typescript, aktuelle Vim Plugins, Static Page Generatoren und viele andere Themen aus dem Bereich der Nerdwelt.",
      "In der ersten Folge, reden die 4 Nerdkundler über's Wetter, Notizen, das digitale Testament, RSS Reader, ein Spiel in dem man Spiele herstellt und kommende und vergangene Events.",
      "In dieser ausgeweiteten Episode unterhalten sich die 4 Nerdkundler über die Google I/O, App.net, Podcatcher, Grafiktools, Video Codecs und Spiele in Javascript, vim, FISH, hacken.in, die Scottish Ruby Conference und am Pranger steht: Android Entwicklung.",
      "In dieser Folge unterhalten sich Bodo, Tobi und Klaus (ohne Lucas) über Musikgenres, Adressen, SQL Injection Suchmaschinen, Forkwälder, Doom Quellcode und zeitfressende Spiele. Am Pranger diesmal: Das Wasserfall Modell und langsame Tests.",
      "Feier und Trauer. Die letzte Folge mit Bodo in Köln und gleichzeitig auch Klausens Geburtstag. Diesmal geht's um wasserdichte Gadgets, böse Ladegeräte, ScummVM und WebGL Videofilter, mal wieder Testing und Indiegames. Am Pranger stehen wir diesmal selbst.",
      "Die erste Folge in neuer Besetzung. Heute geht es um freitägliche Internetumarmungen, Google Glass, JavaScript Aluhüte, RubyGem Tools, virtuelle Linuxe, Genderthemen in Spielen und Programmierkids. Am Pranger: Schlechte READMEs",
      "In dieser sommerlichen Folge geht's um alternative Eingabemethoden und User Interfaces, sichere Kurznachrichten und Backups, das Rails-lib-Verzeichnis, die Zukunft von RSpec, Linux 3.11 for Workgroups und die Red Frog Conf. Am Pranger: Glasdisplays.",
      "Die halbe Stammbesetzung fehlt, dafür ist aber Dennis dabei. Wir reden über geklaute exFAT Treiber, die Podcast Szene, 32.000.000$ Crowdfundings, den Apple Developer Hack, iOctocat, und natürlich das RailsCamp 2013, auf dem diese Folge entstanden ist.",
    ]

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
      attr_accessor :podcast, :episode_subtitles, :opengraph
      def episode
        nil
      end
    end.new

    env.podcast = Podcast.from_yaml("podcast.yml")
    env.episode_subtitles = SUBTITLES
    env.opengraph = {
      "og:type"        => "website",
      "og:url"         => "http://www.nerdkunde.de",
      "og:title"       => "Nerdkunde - der Podcast",
      "og:description" => "Substantiv, feminin – Ein Podcast über Nerdkultur und alles was Nerds interessiert. Es sprechen vier Kölner Nerds. Siehe auch: Bodo Tasche, Klaus Zanders, Lucas Dohmen, und Tobias Eilert.",
      "og:image"       => "http://www.nerdkunde.de/images/nerdkunde_logo_small.jpg"
    }
    c = Slim::Template.new("templates/content/index.slim", pretty: true).render(env)
    File.open("public/index.html", "w") do |f|
      f.write(layout.render(env) {c})
    end
  end

  def episode_pages
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
    podcast = Podcast.from_yaml("podcast.yml")
    podcast.episodes.each_with_index do |episode|
      env = Class.new do
        attr_accessor :podcast, :episode, :description, :opengraph

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
      env.opengraph = {
        "og:type"         => "music.song",
        "og:description"  => SUBTITLES[episode.number],
        "og:audio"        => podcast.episode_media_url(episode, podcast.formats.first),
        "og:title"        => episode.title,
        "og:image"        => "http://www.nerdkunde.de/images/nerdkunde_logo_small.jpg",
        "og:url"          => "http://www.nerdkunde.de/nk#{"%04d" % episode.number}.html",
        "music:duration"  => episode.length
      }

      c = Slim::Template.new("templates/content/episode.slim", pretty: true).render(env)
      File.open("public/nk#{"%04d" % episode.number}.html", "w") do |f|
        f.write(layout.render(env) {c})
      end
    end
  end

  def markdown_files
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

    Dir.glob("templates/content/*.markdown").each do |md|
      mdfile = File.open(md, "rb").read
      File.open(File.join("public", "#{File.basename(md, ".markdown")}.html"), "w") do |f|
        f.write(layout.render(OpenStruct.new(opengraph: {})) {renderer.render(mdfile)})
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
    sass_engine = Sass::Engine.new(template, load_paths: load_paths)
    FileUtils.mkdir("public/stylesheets") unless File.exist?("public/stylesheets")
    File.open("public/stylesheets/base.css", "w") do |f|
      f.write sass_engine.render
    end

    mobile_engine = Sass::Engine.new(File.read('templates/stylesheets/mobile.sass'))
    File.open("public/stylesheets/mobile.css", "w") do |f|
      f.write mobile_engine.render
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
