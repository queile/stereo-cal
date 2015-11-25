require 'open-uri'
require 'nokogiri'
require 'time'

require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'

APPLICATION_NAME = 'Stereo Tokyo Calendar'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.json")
SCOPE = 'https://www.googleapis.com/auth/calendar'
CALENDAR_ID = '255kfu2kdqtbblu5r6avbcm6dk@group.calendar.google.com'

def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  file_store = Google::APIClient::FileStore.new(CREDENTIALS_PATH)
  storage = Google::APIClient::Storage.new(file_store)
  auth = storage.authorize

  if auth.nil? || (auth.expired? && auth.refresh_token.nil?)
    app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
    flow = Google::APIClient::InstalledAppFlow.new({
      :client_id => app_info.client_id,
      :client_secret => app_info.client_secret,
      :scope => SCOPE})
    auth = flow.authorize(storage)
    puts "Credentials saved to #{CREDENTIALS_PATH}" unless auth.nil?
  end
  auth
end

def scrape()
	url = 'http://www.st-tokyo.com/'

	charset = nil
	html = open(url) do |f|
		charset = f.charset
		f.read
	end

	plan_list = []
	doc = Nokogiri::HTML.parse(html, nil, charset)
	doc.xpath('//div[contains(@class, "s-item-text-group")]').each do |group|
		group.xpath('div[@class="s-item-title"]//h3').each do |node|
			text = node.inner_text
			begin
				plan = {}
				date = Time.parse(text)
				title = node.xpath('div')[1].inner_text rescue text
				p title
				p date
				plan["summary"] = title
				plan["start"] = {:date => date.strftime("%Y-%m-%d")}
				plan["end"] = {:date => date.strftime("%Y-%m-%d")}

				place_flag = false
				description = ""
				group.xpath('div[contains(@class, "s-item-text")]//div').each do |s_item|
					if place_flag
						s_item_innner = s_item.xpath('div')
						place = s_item_innner[0].inner_text rescue s_item.inner_text
						p place
						plan["location"] = place
						place_flag = false
					end
					place_flag = true if s_item.inner_text == "Place"
				end
				group.xpath('div[contains(@class, "s-item-text")]
					//div[contains(@class, "s-component-content")]//div').each do |content|
					description += content.inner_text + "\n"
				end
				plan["description"] = description.gsub("\u00A0","").strip
				plan_list.push(plan)
			rescue

			end
		end
	end

	p plan_list

	return plan_list
end

def refresh_cal(plan_list)
	client = Google::APIClient.new(:application_name => APPLICATION_NAME)
	client.authorization = authorize
	calendar_api = client.discovered_api('calendar', 'v3')

	#List all events
	results = client.execute!(
	  :api_method => calendar_api.events.list,
	  :parameters => {
	    :calendarId => CALENDAR_ID,
	    })
	p results.data

	#Delete all events
	results.data.items.each do |event|
	  client.execute!(
	    :api_method => calendar_api.events.delete,
	    :parameters => {
	      :calendarId => CALENDAR_ID,
	      :eventId => event.id
	    })
	end

	plan_list.each do |plan|
		results = client.execute!(
			:api_method => calendar_api.events.insert,
			:parameters => {
				:calendarId => CALENDAR_ID
			},
			:body => JSON.dump(plan),
			:headers => {
				'Content-Type' => 'application/json'
			}
		)
		p results
	end
end

plan_list = scrape()
refresh_cal(plan_list)