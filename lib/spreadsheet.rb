require 'axlsx'
require 'pry'

module TrelloScrum

  class Spreadsheet

    attr_reader :package, :workbook

    def initialize
      @package = Axlsx::Package.new
      @workbook = @package.workbook
    end

    def render_cards(lists_with_cards)
      list_name_style = workbook.styles.add_style :sz => 16, :b => true
      header_style = workbook.styles.add_style :b => true

      workbook.add_worksheet(:name => "Cards") do |sheet|
        lists_with_cards.each do |list|
          # The list title
          sheet.add_row [
            list[:list].name.to_s + (list[:list].closed ? " (archived)" : "")
          ], style: list_name_style

          # Header
          sheet.add_row [
            "Points",
            "Title",
            "Client",
            "URL"
          ], style: header_style

          list[:cards].each do |card|
            sheet.add_row [
              card.scrum_points,
              card.scrum_title,
              card.scrum_client,
              card.url
            ]
          end

          # Add some empty rows
          sheet.add_row
        end

        sheet.column_widths 10, nil, nil, nil
      end
    end

    def save(filename)
      package.serialize(filename)
    end
  end

end