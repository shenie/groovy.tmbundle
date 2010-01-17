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

classpath_entries = []
classpath_entries << clazz_dir if File.exists?(clazz_dir)

idea_lib = "#{Dir.pwd}/.idea/libraries/dependencies.xml"
if File.exists?(idea_lib)
  require 'rubygems'
  require 'nokogiri'

  doc = Nokogiri::XML(File.open("#{Dir.pwd}/.idea/libraries/dependencies.xml"))
  jars = doc.search('//root').collect {|r| [Dir.pwd, 'ivy-cache', r.attributes['url'].text.gsub(/!/, '').split('/')[4..-1]].flatten.join('/') }

  classpath_entries << jars
end

grails_home = ENV['GRAILS_HOME']
grails_dist = "#{grails_home}/dist"
if File.exists?(grails_dist)
  classpath_entries << Dir.glob("#{grails_dist}/*.*")
end

grails_lib = "#{grails_home}/lib"
if File.exists?(grails_lib)
  classpath_entries << Dir.glob("#{grails_lib}/*.*")
end

classpath_entries.flatten!
unless classpath_entries.empty?
  cmd << "-cp"
  cmd << classpath_entries.join(':')
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

