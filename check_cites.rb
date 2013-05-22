#!/usr/bin/env ruby
# encoding: utf-8
#
# Check which bibliographic entries were actually referenced
# 
# Usage: check_cites.rb [bibliography file]
#

required_rainbow = begin
                       require "rainbow"
                   rescue LoadError => e
                       raise unless e.message =~ /rainbow/
                       puts "Note: Installing the gem 'rainbow' gives you fancy colors"
                       false
                   end
unless required_rainbow
    class String
        def color _
            self
        end
    end
end

input_file = (ARGV.first || "bibliography.bib")

if !File.exists?(input_file)
    raise Exception.new("Input bibliography file `#{input_file}` not found")
end

puts "Accumulating available references".color(:green)
references = File.open(input_file) do |f|
    f.readlines.map(&:chomp).grep(/^@/).map do |line|
        line.split("{")[1].gsub(/,/,"")
    end
end

found = Hash.new(false)

puts "Search citations".color(:green)
references.each do |reference|
    Dir.glob("*.tex") do |file|
        citations = File.open(file){|f| f.grep(/#{reference}/)}
        unless citations.empty?
            found[reference] = true
        end
    end
end

puts "Uncited references from #{input_file}:".color(:red)
puts references.select{|reference| not found[reference]}.to_s

puts "Checking if unfound references are mentioned in the bibliography".color(:green)

bib_items = Hash.new(false)

ran_before = false
Dir.glob("*.bbl") do |bibliography|
    if ran_before
        warn "There exists more than one *.bbl file. This can lead to errors".color(:red)
    end
    ran_before = true
    File.open(bibliography) do |f|
        f.grep(/bibitem/).map do |items|
            match_results = items.match(/{([^\\}]*)}$/).captures
            unless match_results.empty?
                if match_results.size > 1
                    raise Exception.new("Captured more than one reference")
                end
                bib_items[match_results.first] = true
            end
        end
    end
end

not_found_but_in_bibliography =
    references.select{|reference| bib_items[reference] and not found[reference]}

if not_found_but_in_bibliography.empty?
    puts "No uncited entries in the bibliography".color(:blue)
else
    puts "Uncited entries in the bibliography".color(:red)
    puts not_found_but_in_bibliography.to_s
end
