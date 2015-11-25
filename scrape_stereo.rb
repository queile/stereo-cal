require 'open-uri'
require 'nokogiri'
require 'time'

url = 'http://www.st-tokyo.com/'

charset = nil
html = open(url) do |f|
	charset = f.charset
	f.read
end

#date = nil

doc = Nokogiri::HTML.parse(html, nil, charset)
doc.xpath('//div[contains(@class, "s-item-text-group")]').each do |group|
	group.xpath('div[@class="s-item-title"]//h3').each do |node|
		text = node.inner_text
		begin
			date = Time.parse(text)
			title = node.xpath('div')[1].inner_text rescue text
			p title
			p date

			place_flag = false
			group.xpath('div[contains(@class, "s-item-text")]//div').each_with_index do |s_item, i|
				if place_flag
					s_item_innner = s_item.xpath('div')
					place = s_item_innner[0].inner_text rescue s_item.inner_text
					p place 
					break
				end
				place_flag = true if s_item.inner_text == "Place"
			end
		rescue

		end
	end
end