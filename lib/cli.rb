require 'thor'

require 'json'
require 'chronic'
require 'trello'
require 'launchy'

require_relative 'pdf'

module TrelloScrum
  class Cli < Thor
    class_option :"config", :default => "./config.json", :type => :string, :desc => "Path to config, default is local directory/config.json"
    class_option :"verbose", :aliases => ["v"], :default => false, :type => :boolean, :desc => "Verbose output"


    desc "pdf OUTFILE", "generate PDF for cards"
    method_option :"only-estimated", :default => true, :type => :boolean, :desc => "Wether or not to output only estimates"
    method_option :"list", :type => :string, :desc => "Listname to use"
    method_option :"board", :type => :string, :desc => "Board id to use"
    method_option :"filter-title", :type => :string, :desc => "Regexp to filter on titles, only show's cards matching title"

    def pdf(outfile)
      setup_trello
      cards = get_cards
      generate_pdf(cards, outfile)
    end

    desc "setup DEVELOPER_PUBLIC_KEY MEMBER_TOKEN [BOARD_ID] [LIST_NAME]", "config trello"
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

      3. Run setup with the just generated tokens.

    EOT
    def setup(developer_public_key, member_token, board_id=nil, list_name=nil)
      self.config["developer_public_key"] = developer_public_key
      self.config["member_token"] = member_token
      self.config["board_id"] = board_id if board_id
      self.config["list_name"] = list_name if list_name

      write_config!
    end

    desc "authorize", "Re-authorize trello"
    long_desc <<-EOT
      A simple way to launch the browser with the correct url. It will
      also provide you with a way to paste your MEMBER_TOKEN.
    EOT
    def authorize
      # Open the browser
      url = "https://trello.com/1/connect"
      url << "?key=#{self.config["developer_public_key"]}"
      url << "&name=TrelloScrumCard&response_type=token"
      Launchy.open(url)

      member_token = ask("Paste member token here:")

      if member_token =~ /.+/
        self.config["member_token"] = member_token
        write_config!
      else
        say "No member token entered. Not saving new member token"
      end
    end

    protected

    def write_config!
      File.open(options.config, "w") do |f|
        f.write JSON.pretty_generate(self.config)
      end
      say "Config written to #{options.config}"
    end

    def log(msg)
      say msg if options.verbose
    end

    def setup_trello
      if !config["developer_public_key"] || config["developer_public_key"].empty?
        say "Please make sure you have configured a developer public key (run setup help for more info)"
        exit(1)
      end

      if !config["member_token"] || config["member_token"].empty?
        say "Please make sure you have configured a member token (run setup help for more info)"
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
        say "Please enter a listname (using --list) or configure one using setup"
        exit(1)
      end

      board_id = options.board || config["board_id"]

      if !board_id || board_id.empty?
        say "Please enter a board_id (using --board) or configure one using setup "
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
      pdf = Pdf.new
      pdf.render_cards(cards)
      pdf.save(output_path)
    end



  end
end