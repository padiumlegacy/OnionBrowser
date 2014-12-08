#!/usr/bin/ruby
#
# convert all HTTPS Everywhere XML rule files into one big rules hash and write
# it out as a plist, as well as a standalone hash of target URLs -> rule names
# to another plist
#

require "active_support/core_ext/hash/conversions"
require "plist"

rules = {}
targets = {}

Dir.glob(File.dirname(__FILE__) +
"/https-everywhere/src/chrome/content/rules/*.xml").each do |f|
  hash = Hash.from_xml(File.read(f))

  raise "no ruleset" if !hash["ruleset"]

  if hash["ruleset"]["default_off"]
    next # XXX: should we store these?
  end

  raise "conflict on #{f}" if rules[hash["ruleset"]["name"]]

  rules[hash["ruleset"]["name"]] = hash

  hash["ruleset"]["target"].each do |target|
    if !target.is_a?(Hash)
      # why do some of these get converted into an array?
      if target.length != 2 || target[0] != "host"
        puts f
        raise target.inspect
      end

      target = { target[0] => target[1] }
    end

    if targets[target["host"][1]]
      raise "rules already exist for #{target["host"]}"
    end

    targets[target["host"]] = hash["ruleset"]["name"]
  end
end

File.write("https-everywhere_targets.plist", targets.to_plist)
File.write("https-everywhere_rules.plist", rules.to_plist)
