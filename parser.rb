class Parser

  def initialize(month=1, day=1)
    @month = curate(month)
    @day = curate(day)
    @doc = Nokogiri::HTML(open(generate_url))
    parse
  end

  def events_html
    output = "<div class='efemerides'>"
    @years.each_with_index do |year, index|
      output << "<div class='efemeride'>"
      output << "<span class='year'>" + year.strip + "</span> "
      output <<  @texts[index].strip + "</div>"
    end
    output << "</div>"
  end

  def events
    output = []
    @years.each_with_index { |year, index| output << [year.strip, @texts[index].strip] }
    output
  end

  def events_hash
    output = []
    @years.each_with_index do |year, index|
      output << {
        :year => year.strip,
        :day => @day,
        :month => @month,
        :content => @texts[index].strip
      }
    end
    output
  end

private

  def curate(num)
    num[0] == "0" ? num[1] : num
  end

  def generate_url
    base_url = "http://www.me.gov.ar/efeme/index.html"
    base_url + "?mes=#{@month}&dia=#{@day}"
  end

  def parse
    content =  @doc.css('blockquote p font')
    puts content.text
    @years = content.text.scan(/\s\d{4}\s/)
    @texts = content.text.strip.split(/\d{4}\s/).reject { |t| t.strip == "" }
  end

end
