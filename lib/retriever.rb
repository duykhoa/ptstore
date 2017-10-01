require 'tracker_api'
require 'json'

class Retriever
  def initialize(project_id, token)
    @project_id, @token = project_id, token
  end

  def stories(filter_options)
    project.stories(filter_options)
  end

  attr_reader :token, :project_id

  def client
    TrackerApi::Client.new(token: token)
  end

  def project
    @project ||= client.project(project_id)
  end
end

class FileIO
  def initialize(path)
    @path = path
  end

  def <<(content)
    File.open(@path, "w+") do |f|
      f.write(content)
    end
  rescue IOError => e
    STDOUT << "There was an error when writing to file, #{e}"
  end
end

class Main
  def initialize(retriever, io, logger = nil)
    @retriever = retriever
    @io = io
    @logger = logger || Logger.new(STDOUT)
  end

  def call(filter_cond)
    @logger.info "START"

    persisted(
      serialized_stories(filter_cond),
      @io
    )
  end

  def serialized_stories(filter_cond)
    @logger.info("Sending request to Pivotal Tracker API")

    JSON.generate serialize(filtered_stories(filter_cond))
  end

  def filtered_stories(filter_cond)
    @logger.info("Retrieved Stories Data")

    @retriever.stories(filter_cond)
  end

  def persisted(serialized_stories, io)
    @logger.info("Persisting data")
    io << serialized_stories
  end

  def serialize(stories)
    @logger.info("Serialize Data")

    stories.map do |story|
      attributes story
    end
  end

  def attributes(story)
    {
      name: story.name,
      estimate: story.estimate,
      story_type: story.story_type,
      url: story.url,
      description: story.description,
      transitions: transitions(story)
    }
  end

  def transitions(story)
    story.transitions.map do |tran|
      {
        state: tran.state,
        occurred_at: tran.occurred_at
      }
    end
  end
end
