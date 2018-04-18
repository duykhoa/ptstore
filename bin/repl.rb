#!/usr/bin/env ruby

require "pry"
require "date"
require "yaml"

require_relative "../lib/retriever"

config = OpenStruct.new(YAML.load_file(".config.yaml"))
accepted_after = config[:accepted_after]
project_id     = config[:project_id]

token          = config[:token]
output         = config[:output]

filter_conds = {
  accepted_after: DateTime.parse(accepted_after).iso8601
}

retriever = Retriever.new(project_id, token)
fileio = FileIO.new(output)

@main = Main.new(retriever, fileio)
@main.call(filter_conds)
