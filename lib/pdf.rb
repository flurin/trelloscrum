require 'prawn'
require 'prawn/table'

module TrelloScrum
  class Pdf

    attr_reader :doc, :options

    def initialize(page_size = 'A4', options = {})

      @options = {
        base_font_size: 20
      }.update(options)

      @doc = Prawn::Document.new :page_size => page_size, :page_layout => :landscape

      self.doc.font_families.update("FontAwesome" => {:normal => "#{File.dirname(__FILE__)}/../resources/fontawesome-webfont.ttf"})

      self.doc.font_families.update(
        "OpenSans" => {
          :normal => "#{File.dirname(__FILE__)}/../resources/OpenSans-Regular.ttf",
          :bold => "#{File.dirname(__FILE__)}/../resources/OpenSans-Bold.ttf",
          :bold_italic => "#{File.dirname(__FILE__)}/../resources/OpenSans-BoldItalic.ttf",
          :italic => "#{File.dirname(__FILE__)}/../resources/OpenSans-Italic.ttf"
        }
      )

      self.doc.font "OpenSans", :size => self.options[:base_font_size]


    end

    def render_cards(cards)
      cards.each_with_index do |card, i|
        render_card(card)

        # Start next card on new page
        self.doc.start_new_page unless i == cards.size - 1
      end
    end

    def save(filename)
      self.doc.render_file filename
    end

    protected

    def render_card(card)
      points,client,title = parse_card_title(card.name)

      puts "- #{points} :: #{client} :: #{title}"

      box_width = 100

      # Output storypoints
      points_box_size = render_points_box(points)

      self.doc.bounding_box([0, self.doc.cursor], :width => self.doc.bounds.width - points_box_size) do
        self.doc.text(client, {
          :size => self.options[:base_font_size],
          :overflow => :expand
        })

        self.doc.text(title, {
          :size => self.options[:base_font_size] * 2.25,
          :style => :bold,
          :overflow => :expand
        })
      end

      # Output due date
      render_due_date(card.due)

      self.doc.move_down 10

      if card.checklists.any?
        # Take half the size of the remaining card for description, leave the rest fot checklists
        # Yes, taking doc.cursor is weird, but keep in mind the coordinate system's origin is bottom left
        desc_height = doc.cursor / 2
      else
        desc_height = doc.cursor
      end

      # Manually creating box here so we can get heigh later.
      desc_box = Prawn::Text::Box.new(card.desc,
        at: [0, self.doc.cursor],
        width: self.doc.bounds.width,
        height: desc_height,
        overflow: :shrink_to_fit,
        document: self.doc)


      desc_box.render()

      # Textbox doesn't move the cursor so we'll do it manually
      self.doc.move_down desc_box.height

      if card.checklists.any?
        self.doc.move_down 20

        card.checklists.each do |checklist|
          render_checklist(checklist)
        end
      end

    end

    def render_checklist(checklist)
      data = checklist.items.map do |item|
        [
          (item.state != "complete" ? "\uF096" : "\uF046"),
          item.name
        ]
      end

      if data.any?
        self.doc.text(checklist.name, {
          :style => :bold
        })

        table_height = self.doc.cursor

        table = nil
        real_table_height = self.doc.bounds.height + 1 # Should always be bigger than table_height
        table_font_size = self.options[:base_font_size]
        while(real_table_height > table_height && table_font_size > 8) do
          table = Prawn::Table.new(data, self.doc) do |tbl|
            tbl.width = self.doc.bounds.width
            tbl.cells.size = table_font_size
            tbl.cells.borders = []
            if table_font_size < 15
              tbl.cells.padding = [0,0,2,0]
              tbl.column(0).padding = [1.5,0,2,0]
            else
              tbl.cells.padding = [0,0,5,0]
            end
            tbl.column(0).font = "FontAwesome"
            tbl.column(0).width = table_font_size + 2
          end
          real_table_height = table.height
          table_font_size -= 1
        end

        table.draw
      end
    end

    def render_due_date(date)
      return unless date

      date_text = date.strftime("%-d %^B")

      due_box_text = {
        text: date_text,
        color: "FF0000",
        styles: [:bold],
        style: :bold, # Hack to make it work for width measuring too...
        size: self.options[:base_font_size] * 3
      }

      due_box_width = self.doc.width_of(due_box_text[:text], due_box_text)
      due_box_height = self.doc.height_of_formatted([due_box_text], {})

      due_box = Prawn::Text::Formatted::Box.new([due_box_text], {
        at: [self.doc.bounds.right - due_box_width, self.doc.bounds.absolute_bottom],
        width: due_box_width,
        height: due_box_height,
        disable_wrap_by_char: true,
        align: :right,
        overflow: :shrink_to_fit,
        document: doc
      })

      due_box.render()
    end

    def render_points_box(points)
      return 0 if points.to_s.empty?

      points_box_size = 100
      points_box_padding = 10

      points_box = Prawn::Text::Box.new(points.to_s,
        {
          at: [self.doc.bounds.absolute_right - points_box_size + points_box_padding, self.doc.bounds.absolute_top - points_box_padding],
          align: :center,
          valign: :center,
          disable_wrap_by_char: true,
          width: points_box_size - 2 * points_box_padding,
          height: points_box_size - 2 * points_box_padding,
          size: 60,
          style: :bold,
          overflow: :shrink_to_fit,
          document: self.doc
        }
      )

      points_box.render

      self.doc.stroke do
        self.doc.rectangle [self.doc.bounds.absolute_right - points_box_size, self.doc.bounds.absolute_top], points_box_size, points_box_size
      end

      return points_box_size
    end

    def parse_card_title(title)
      match = title.match(/^\s*(\((\d+)\))?\s*(\[(.*?)\])?\s*(.*)/)
      [match[2], match[4], match[5]]
    end

  end
end