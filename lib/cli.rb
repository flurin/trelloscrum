require 'thor'

require 'json'
require 'prawn'
require 'chronic'
require 'trello'

module TrelloScrum
  class Cli < Thor
    class_option :"config", :default => "./config.json", :type => :string, :desc => "Path to config, default is local directory/config.json"
    class_option :"verbose", :aliases => ["v"], :default => false, :type => :boolean, :desc => "Verbose output"


    desc "pdf OUTFILE", "generate PDF for cards"
    method_option :"only-estimated", :default => true, :type => :boolean, :desc => "Wether or not to output only estimates"
    method_option :"list", :type => :string, :desc => "Listname to use"
    method_option :"board", :type => :string, :desc => "Board id to use"
    method_option :"filter-title", :type => :string, :desc => "Regexp to filter on titles, only show's cards matching title"

  desc "setup DEVELOPER_PUBLIC_KEY MEMBER_TOKEN [BOARD_ID]", "config trello"
  long_desc <<-EOT
    Generate the appropriate keys for Trello:

    1. Get the developer public key
    \x5  1. Log in to Trello
    \x5  2. Go to https://trello.com/1/appKey/generate
    \x5  3. Save the developer public key

    2. Get the member token
    \x5  1. Go to https://trello.com/1/connect?key=DEVELOPER_PUBLIC_KEY&name=TrelloScrumCard&response_type=token
            Replace DEVELOPER_PUBLIC_KEY with the previously generated key
    \x5  2. Click "Allow"
    \x5  3. Save the member token

  EOT
  def setup(developer_public_key, member_token, board_id=nil)
    self.config["developer_public_key"] = developer_public_key
    self.config["member_token"] = member_token
    self.config["board_id"] = board_id if board_id

    File.open(options.config, "w") do |f|
      f.write JSON.pretty_generate(self.config)
    end

    puts "New config written to #{options.config}"
  end

  protected

  def log(msg)
    puts msg if options.verbose
  end

  def setup_trello
    if !config["developer_public_key"] || config["developer_public_key"].empty?
      puts "Please make sure you have configured a developer public key (run setup help for more info)"
      exit(1)
    end

    if !config["member_token"] || config["member_token"].empty?
      puts "Please make sure you have configured a member token (run setup help for more info)"
      exit(1)
    end

    Trello.configure do |c|
      c.developer_public_key = config["developer_public_key"]
      c.member_token = config["member_token"]
    end
  end

  def config
    if File.exist?(options.config)
      @config ||= JSON.parse(File.read(options.config));
    else
      @config ||= {}
    end
  end

  def get_cards
    list_name = options.list || config["list_name"]

    if !list_name || list_name.empty?
      puts "Please enter a lisname or configurate one (use --list)"
      exit(1)
    end

    board_id = options.board || config["board_id"]

    if !board_id || board_id.empty?
      puts "Please enter a board_id or configurate one (use --board)"
      exit(1)
    end

    log "Getting cards from list #{list_name} of board #{board_id}"

    board = Trello::Board.find(board_id)

    list = board.lists.find{|l| l.name == list_name }

    log "Found list: #{list ? "yes" : "no"}"

    cards = list.cards.sort!{|a, b| a.pos <=> b.pos }

    log "List contains #{cards.size} cards"

    cards.find_all do |card|
      keep = true
      keep = false if options[:"only-estimated"] && !(card.name =~ /^\(\d+/)
      keep = false if options[:"filter-title"] && !(card.name =~ Regexp.new(options[:"filter-title"]))
      keep
    end
  end

  def generate_pdf(cards, output_path)
    pdf = Prawn::Document.new :page_size => 'A4', :page_layout => :landscape

    pdf.font_families.update("FontAwesome" => {:normal => "#{File.dirname(__FILE__)}/../resources/fontawesome-webfont.ttf"})
    pdf.font "Helvetica", :size => 20

    puts cards.length

    cards.each_with_index do |card, i|
      points,client,title = parse_card_title(card.name)

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
  end

  def parse_card_title(title)
    match = title.match(/^\s*(\((\d+)\))?\s*(\[(.*?)\])?\s*(.*)/)
    [match[2], match[4], match[5]]
  end

end