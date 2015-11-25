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
doc.xpath('//div[@class="s-item-title"]//h3').each do |node|
	#node.xpath('div').each do |div|
		text = node.inner_text
		#if date
		#	p node.inner_text
		#	p date
		#	date = nil
		#	next
		#end
		begin
			date = Time.parse(text)
			title = node.xpath('div')[1].inner_text rescue text
			p title
			p date
		rescue

		end
	#end
end