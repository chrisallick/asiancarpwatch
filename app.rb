require 'sinatra'
require 'sinatra/partial'
require 'sinatra/reloader' if development?

require "sinatra/jsonp"

require './config.rb'

require 'open-uri'
require 'nokogiri'

# http://ac55f02d.ngrok.io/parse/
# http://ac55f02d.ngrok.io/latlong/?site_no=04231600
# http://ac55f02d.ngrok.io/distance/?site_no=04231600&number=4153006890&distance=2.3
# http://ac55f02d.ngrok.io/sites/



# january 1st 2015 and 650 will not be reached until around July

# http://waterdata.usgs.gov/mi/nwis/uv?cb_00055=on&cb_00010=on&format=rdb&site_no=04119400&period=&begin_date=2016-04-08&end_date=2016-04-23
# Data for the following 1 site(s) are contained in this file
#    USGS 04119400 GRAND RIVER NEAR EASTMANVILLE, MI
# -----------------------------------------------------------------------------------
#
# Data provided for site 04119400
#    DD parameter   Description
#    04   00055     Stream velocity, feet per second
#    06   00010     Temperature, water, degrees Celsius

# http://nwis.waterdata.usgs.gov/mi/nwis/uv/?cb_00055=on&cb_00010=on&format=rdb&site_no=04119400&period=&begin_date=2014-07-01&end_date=2014-07-15 


# http://waterdata.usgs.gov/nwis/uv?cb_00055=on&cb_00010=on&format=rdb&site_no=04087170&period=&begin_date=2016-04-08&end_date=2016-04-23
# Data for the following 1 site(s) are contained in this file
#    USGS 04087170 MILWAUKEE RIVER AT MOUTH AT MILWAUKEE, WI
# -----------------------------------------------------------------------------------
#
# Data provided for site 04087170
#    DD parameter   Description
#    49   00055     Stream velocity, feet per second, [UPLOOK XR SONTEK EAST]
#    50   00055     Stream velocity, feet per second, [UPLOOK XR SONTEK NORTH]
#    51   00055     Stream velocity, feet per second, [UPLOOK XR SONTEK UP]
#    57   00055     Stream velocity, feet per second, [UPLOOK NORTH XR SONTEK EAST]
#    58   00055     Stream velocity, feet per second, [UPLOOK NORTH XR SONTEK NORTH]
#    59   00055     Stream velocity, feet per second, [UPLOOK NORTH XR SONTEK UP]
#    64   00010     Temperature, water, degrees Celsius, [YSI UP]
#    69   00010     Temperature, water, degrees Celsius, YSI DOWN

client = Twilio::REST::Client.new Config.getSID(), Config.getToken()

configure do
    redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
    uri = URI.parse(redisUri) 
    $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

    # if $redis.get("conversation_counter")
    #     $redis.set("conversation_counter", $redis.get("conversation_counter") )
    # else
    #     $redis.set("conversation_counter", 0 )
    # end
end

#file_name = "sample_short.txt"
#file_name = "sample.txt"
#file_name = "sample_july_15_30_2015.txt"
file_name = "sample_04_08_23_2016.txt"

get '/parse/' do
    content_type :json

    header_found = false
    spacer_found = false
    dt_i = 0
    t_i = 0
    v_i = 0
    headers = []
    temps = {}
    speeds = {}
    parsed_order = false
    File.open(file_name).each do |line|
        if line[0].chr == "#"
            puts "header..."
        else
            if !header_found
                puts "header"
                puts line
                headers = line.split("\t")

                header_found = true
            elsif !spacer_found
                puts "spacer"
                puts line

                spacer_found = true
            elsif !parsed_order
                cols = line.split("\t")
                
                dt_i = headers.index("datetime")
                v_i = headers.index("04_00055")
                t_i = headers.index("06_00010")

                date = Time.parse(cols[dt_i])
                dt = date.strftime("%Y-%m-%d")

                temps[dt] = [cols[t_i].to_f]
                speeds[dt] = [cols[v_i].to_f]

                parsed_order = true
            else
                cols = line.split("\t")

                date = Time.parse(cols[dt_i])
                dt = date.strftime("%Y-%m-%d")

                if !temps[dt] || !speeds[dt]
                    temps[dt] = [cols[t_i].to_f]
                    speeds[dt] = [cols[v_i].to_f]
                else
                    if cols[t_i] == "" || cols[v_i] == ""
                        # blank data point
                    else
                        temps[dt].push( cols[t_i].to_f )
                        speeds[dt].push( cols[v_i].to_f )
                    end
                end            
            end
        end
    end

    total = 0
    temps.each do |key, value|
        avg = value.reduce(:+).to_f / value.size
        avg = avg.round(2)

        temps[key] = avg

        total += avg
    end

    speeds.each do |key, value|
        avg = value.reduce(:+).to_f / value.size
        speeds[key] = (avg * 0.3048).round(4)
    end

    data = { :temps => temps, :sum => total, :speeds => speeds }.to_json

    return data
end

get '/' do
    content_type :json

    return { :result => "success", :msg => "hello from fishackathon v1.0" }.to_json
end

not_found do
    return { :result => "error", :msg => "url not found" }.to_json
end

# 43°08'30.2"
# 77°36'58.7"
# 43.14172222222222, 77.61630555555556

# example
# 04231600
# http://2e7a3b02.ngrok.io/latlong/?site_no=04231600

get '/latlong/' do
    content_type :json

    if params[:site_no]
        url = "http://waterdata.usgs.gov/ny/nwis/nwismap/?site_no=#{params[:site_no]}&agency_cd=USGS"
        doc = Nokogiri::HTML(open(url))
        text = doc.at('div:contains("Latitude")').text
        parts = text.tr(",", "").split(" ")
        
        parts[1] = parts[1].tr("°", " ")
        parts[1] = parts[1].tr("'", " ")
        parts[1] = parts[1].tr("\"", "")
        lat = parts[1].split(" ")

        lat = lat[0].to_f + (lat[1].to_f/60) + (lat[2].to_f/3600)

        parts[3] = parts[3].tr("°", " ")
        parts[3] = parts[3].tr("'", " ")
        parts[3] = parts[3].tr("\"", "")
        lon = parts[3].split(" ")

        lon = lon[0].to_f + (lon[1].to_f/60) + (lon[2].to_f/3600)

        new_object = {
            :site_no => params[:site_no],
            :lat => lat,
            :lon => lon
        }

        $redis.lpush("usgs_sites", params[:site_no])
        $redis.set("usgs_site:#{params[:site_no]}", new_object.to_json )

        data = { :result => "success", :lat => lat, :lon => -lon }.to_json

        JSONP data
    else
        { :result => "error" }.to_json
    end
end

get '/distance/' do
    content_type :json

    if params[:site_no] and params[:distance] and params[:number]
        sid = client.account.messages.create(
            :from => "+13234982368",
            :to => "#{params[:number]}",
            :body => "You are now registered for notifications."
        )

        site_object = JSON.parse( $redis.get("usgs_site:#{params[:site_no]}") )
        site_object["number"] = params[:number]
        site_object["distance"] = params[:distance]
        
        $redis.set("usgs_site:#{params[:site_no]}", site_object.to_json )

        data = { :result => "success" }.to_json

        JSONP data
    else
        { :result => "error" }.to_json
    end
end

get '/sites/' do
    content_type :json

    sites = []
    all_sites = $redis.lrange("usgs_sites", 0, $redis.llen("usgs_sites"))
    all_sites.each do |site|
        site_object = JSON.parse( $redis.get("usgs_site:#{site}") )
        sites.push( site_object )
    end

    data = { :result => "success", :data => sites }.to_json
    JSONP data
end




