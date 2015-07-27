module TrelloScrum

  class TrelloInterface

    attr_accessor :board_id, :options

    def initialize(board_id, developer_public_key, member_token, options = {})
      Trello.configure do |c|
        c.developer_public_key = developer_public_key
        c.member_token = member_token
      end

      self.board_id = board_id

      self.options = options
    end


    def get_cards(list_name = nil, options = {})
      log "Getting cards from list #{list_name} of board #{board_id}"

      lists = get_lists(list_name, options)

      lists.map do |list|
        cards = list.cards.sort!{|a, b| a.pos <=> b.pos }

        log "List '#{list.name}' contains #{cards.size} cards"

        filtered_cards = cards.find_all do |card|
          keep = true
          keep = false if options[:"only-estimated"] && !(card.name =~ /^\(\d+/)
          keep = false if options[:"filter-title"] && !(card.name =~ Regexp.new(options[:"filter-title"]))
          keep
        end

        filtered_cards.map! do |card|
          class << card
            attr_accessor :scrum_points, :scrum_client, :scrum_title
          end
          points,client,title = parse_card_title(card.name)
          card.scrum_points = points
          card.scrum_client = client
          card.scrum_title = title
          card
        end

        {
          list: list,
          cards: filtered_cards
        }
      end
    end

    def get_lists(list_name, options = {})
      board = Trello::Board.find(board_id)

      lists = board.lists filter: (options[:"include-archived-lists"] ? :all : :open)

      if list_name && !list_name.empty?
        lists = lists.find_all{|l| l.name == list_name }
      end

      lists.sort!{|a, b| a.pos <=> b.pos }

      log "Found lists: #{lists.map(&:name).inspect}"

      lists
    end

    protected

    def parse_card_title(title)
      match = title.match(/^\s*(\((\d+)\))?\s*(\[(.*?)\])?\s*(.*)/)
      [match[2], match[4], match[5]]
    end

    def log(msg)
      if options[:cli]
        options[:cli].log msg
      else
        puts msg
      end
    end


  end

end