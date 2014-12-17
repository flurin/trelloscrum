#!/usr/bin/env ruby
# encoding: UTF-8

require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'json'
require 'prawn'
require 'chronic'
require 'trello'
require 'slop'


args = Slop.parse!(:help => true) do
  banner "Usage: generate.rb [options] outfile.pdf"

  on "only-estimated", "Wether or not to output only estemates"
  on "config=", "Path to config, default is local directory/config.json", :argument => :optional
  on "list=", "Listname to use", :argument => :optional
  on "filter-title=", "Regexp to filter on titles, only show's cards matching title", :argument => :optional
end

config_path = args[:config] || "./config.json";
output_path = ARGV[0] || "./out.pdf";

config = JSON.parse(File.read(config_path));

Trello.configure do |c|
  c.developer_public_key = config["developer_public_key"]
  c.member_token = config["member_token"]
end

config["list_name"] = args[:list] if args[:list]

board = Trello::Board.find(config["board_id"])

list = board.lists.find{|l| l.name == config["list_name"] }

cards = list.cards.sort!{|a, b| a.pos <=> b.pos }

# Start rendering

pdf = Prawn::Document.new :page_size => 'A4', :page_layout => :landscape

pdf.font_families.update("FontAwesome" => {:normal => "#{File.dirname(__FILE__)}/resources/fontawesome-webfont.ttf"})
pdf.font "Helvetica", :size => 20

cards.each_with_index do |card, i| 

  next if args[:"only-estimated"] && card.name =~ /^\(\d+/
  if args[:"filter-title"]
    next unless card.name =~ Regexp.new(args[:"filter-title"])
  end

  puts "- #{card.name}"

  pdf.text(card.name, {
    :size => 45,
    :style => :bold,
    :overflow => :expand
  })

  pdf.move_down 10

  pdf.text(card.desc)

  pdf.move_down 20

  card.checklists.each do |checklist|
    data = checklist.items.map do |item|
      [
        (item.state != "complete" ? "\uF096" : "\uF046"),
        item.name
      ]
    end

    if data.any?
      pdf.text(checklist.name, {
        :style => :bold
      })

      pdf.table(data) do |tbl|
        tbl.width = pdf.bounds.width
        tbl.cells.borders = []
        tbl.cells.padding = [0,0,5,0]
        tbl.column(0).font = "FontAwesome"
        tbl.column(0).width = 20
      end
    end
  end  

  pdf.start_new_page

end

pdf.render_file output_path