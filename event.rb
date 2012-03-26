class Event

  include Mongoid::Document

  field :month,   :type => Integer
  field :day,     :type => Integer
  field :year,    :type => Integer
  field :content, :type => String

  def self.search(month, day)
    if where(:month => month, :day => day).count == 0
      parse_and_store(month, day)
    else
      generate_hash(month, day)
    end
  end

  def self.parse_and_store(month, day)
    parser = Parser.new(month, day)
    output = parser.events_hash
    output.each do |event|
      self.create event
    end
    output
  end

  def self.generate_hash(month, day)
    output = []
    where(:month => month, :day => day).each do |event|
      output << {
        :year => event.year,
        :day => event.day,
        :month => event.month,
        :content => event.content
      }
    end
    output
  end

end