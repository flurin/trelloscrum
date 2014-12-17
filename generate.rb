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

def parse_title(title)
  match = title.match(/^\s*(\((\d+)\))?\s*(\[(.*?)\])?\s*(.*)/)
  [match[2], match[4], match[5]]
end

pdf = Prawn::Document.new :page_size => 'A4', :page_layout => :landscape

pdf.font_families.update("FontAwesome" => {:normal => "#{File.dirname(__FILE__)}/resources/fontawesome-webfont.ttf"})
pdf.font "Helvetica", :size => 20

cards.each_with_index do |card, i| 

  next if args[:"only-estimated"] && card.name =~ /^\(\d+/
  if args[:"filter-title"]
    next unless card.name =~ Regexp.new(args[:"filter-title"])
  end

  points,client,title = parse_title(card.name)

  puts "- #{points} :: #{client} :: #{title}"

  box_width = 100

  if points
    pdf.canvas do
      pdf.bounding_box([pdf.bounds.absolute_right - box_width, pdf.bounds.absolute_top], :width => box_width) do
        pdf.move_down 20
        pdf.text(points.to_s, {
          :align => :center,
          :size => 60,
          :style => :bold
        })

        pdf.stroke_color "000000"
        pdf.stroke_bounds
      end
    end
  end

  pdf.move_cursor_to pdf.bounds.top

  pdf.bounding_box([0, pdf.cursor], :width => pdf.bounds.width - box_width) do
    pdf.text(client, {
      :size => 20,
      :overflow => :expand  
    })

    pdf.text(title, {
      :size => 45,
      :style => :bold,
      :overflow => :expand
    })
  end

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