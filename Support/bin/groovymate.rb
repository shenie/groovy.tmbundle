#!/usr/bin/env ruby

require ENV["TM_SUPPORT_PATH"] + "/lib/tm/executor"
require ENV["TM_SUPPORT_PATH"] + "/lib/tm/save_current_document"
require ENV["TM_SUPPORT_PATH"] + "/lib/ui"
require "shellwords"

require "pstore"

class GroovyMatePrefs
  @@prefs = PStore.new(File.expand_path( "~/Library/Preferences/com.macromates.textmate.groovymate"))
  def self.get(key)
    @@prefs.transaction { @@prefs[key] }
  end
  def self.set(key,value)
    @@prefs.transaction { @@prefs[key] = value }
  end
end

TextMate.save_current_document
TextMate::Executor.make_project_master_current_document

cmd = [ENV['TM_GROOVY'] || "groovy"]

clazz_dir = "#{Dir.pwd}/target/classes"
idea_lib = "#{Dir.pwd}/.idea/libraries/dependencies.xml"

if [clazz_dir, idea_lib].all? {|d| File.exists?(d) }
  require 'rubygems'
  require 'nokogiri'

  cmd << "-cp"
  doc = Nokogiri::XML(File.open("#{Dir.pwd}/.idea/libraries/dependencies.xml"))
  jars = doc.search('//root').collect {|r| [Dir.pwd, r.attributes['url'].text.gsub(/!/, '').split('/')[4..-1]].flatten.join('/') }.join(':')

  cmd << "#{Dir.pwd}/target/classes:#{jars}"
end

cmd << ENV['TM_FILEPATH']
script_args = []
if ENV.include? 'TM_GROOVYMATE_GET_ARGS'
  prev_args = GroovyMatePrefs.get("prev_args")
  args = TextMate::UI.request_string(:title => "GroovyMate", :prompt => "Enter any command line options:", :default => prev_args)
  GroovyMatePrefs.set("prev_args", args)
  script_args = Shellwords.shellwords(args)
end

TextMate::Executor.run(cmd, :version_args => ["--version"], :script_args => script_args)

