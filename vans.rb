require 'rubygems'
require 'json'
require 'sinatra/base'
require 'typhoeus'

class VandyVans < Sinatra::Base
  API_KEY = ENV['API_KEY']

  # Stops
  BRANSCOMB_QUAD = '263473'
  CARMICHAEL_TOWERS = '263470'
  HANK_INGRAM = '644903'
  KISSAM = '1198824'
  HIGHLAND_QUAD = '263444'

  # Other Stops
  VUPD = '264041'
  BOOK_STORE = '332298'
  TERRACE_PLACE = '644873'
  WESLEY_PLACE = '1198825'
  NORTH_HOUSE = '263463'
  BLAIR = '264091'
  MCGUGIN_CENTER = '264101'
  MRB_3 = '644874'

  set :logging, true

  before do
    content_type :json
  end

  get '/arrivalTimes' do
    cache_control :private, max_age: 15

    stop_ID = params[:stopID]

    predictions_response = [ ]

    if stop_ID
      hydra = Typhoeus::Hydra.hydra

      routes = self.class.routes_for_stop(stop_ID)

      routes.each do |route|
        logger.info 'Request for Route ' + route.to_s + ' and Stop ' + stop_ID

        request = Typhoeus::Request.new('http://api.syncromatics.com/Route/' + route.to_s + '/Stop/' + stop_ID + '/Arrivals?api_key=' + API_KEY)

        request.on_complete do |response|
          if response.success?
            result = JSON.parse(response.body)
            predictions = result['Predictions']

            logger.info 'Got result: ' + result.to_s

            predictions.each do |prediction|
              predictions_response << {
                'stopID' => prediction['StopId'],
                'routeID' => prediction['RouteId'],
                'minutes' => prediction['Minutes'],
              }
            end
          elsif response.timed_out?
            logger.info 'Request Timed Out'
          elsif response.code == 0
            # Could not get an HTTP response; something's wrong.
            loger.info response.return_message
          else
            logger.info 'HTTP request failed: ' + response.code.to_s
          end
        end

        hydra.queue request
      end

      hydra.run

      logger.info 'Sorting Predictions'

      predictions_response.sort! do |a, b|
        a['minutes'] <=> b['minutes']
      end
    end

    predictions_response.to_json
  end

  get '/vans' do
    cache_control :private, max_age: 3

    route_ID = params[:routeID]

    vans_response = [ ]

    if route_ID
      request = Typhoeus::Request.new('http://api.syncromatics.com/Route/' + route_ID + '/Vehicles?api_key=' + API_KEY)

      request.on_complete do |response|
        if response.success?
          vans = JSON.parse(response.body)

          vans.each do |van|
            vans_response << { 'vanID' => van['ID'], 'latitude' => van['Latitude'], 'longitude' => van['Longitude'], 'percentageFull' => van['APCPercentage'] }
          end
        elsif response.timed_out?
          logger.info 'Request Timed Out'
        elsif response.code == 0
          # Could not get an HTTP response; something's wrong.
          logger.info response.return_message
        else
          logger.info 'HTTP request failed: ' + response.code.to_s
        end
      end

      request.run
    else
      logger.info 'No route ID'
    end

    vans_response.to_json
  end

  get '/waypoints' do
    cache_control :private, max_age: 60

    route_ID = params[:routeID]

    waypoints_response = [ ]

    if route_ID
      request = Typhoeus::Request.new('http://vandyvans.com/Route/' + route_ID + '/Waypoints?api_key=' + API_KEY)

      request.on_complete do |response|
        if response.success?
          waypoints_outer_array = JSON.parse(response.body)
          waypoints = waypoints_outer_array[0]

          waypoints.each do |waypoint|
            waypoints_response << { 'latitude' => waypoint['Latitude'], 'longitude' => waypoint['Longitude'] }
          end
        elsif response.timed_out?
          logger.info 'Request Timed Out'
        elsif response.code == 0
          # Could not get an HTTP response; something's wrong.
          logger.info response.return_message
        else
          logger.info 'HTTP request failed: ' + response.code.to_s
        end
      end

      request.run
    else
      logger.info 'No route ID'
    end

    waypoints_response.to_json
  end

  get '/stops' do
    cache_control :private, max_age: 60

    stops_response = {
        stops: [
            { BRANSCOMB_QUAD => 'Branscomb Quad' },
            { CARMICHAEL_TOWERS => 'Carmichael Towers' },
            { HANK_INGRAM => 'Hank Ingram' },
            { KISSAM => 'College Halls at Kissam' },
            { HIGHLAND_QUAD => 'Highland Quad' },
        ],
        other_stops: [
            { VUPD => 'Vanderbilt Police Department' },
            { BOOK_STORE => 'Vanderbilt Book Store' },
            { TERRACE_PLACE => '21st near Terrace Place' },
            { WESLEY_PLACE => 'Wesley Place Garage' },
            { NORTH_HOUSE => 'North House' },
            { BLAIR => 'Blair School of Music' },
            { MCGUGIN_CENTER => 'McGugin Center' },
            { MRB_3 => 'MRB 3' },
        ],
    }

    stops_response.to_json

  end

  def self.routes_for_stop(stop_ID)
    black = 1857
    gold = 1856
    red = 1858

    routes = [ ]

    case stop_ID
    when BRANSCOMB_QUAD, CARMICHAEL_TOWERS, HIGHLAND_QUAD
      routes = [ black, gold, red ]
    when KISSAM, TERRACE_PLACE
      routes = [ black, gold ]
    when VUPD
      routes = [ red, gold ]
    when BOOK_STORE, NORTH_HOUSE, BLAIR, MCGUGIN_CENTER, MRB_3
      routes = [ gold ]
    when WESLEY_PLACE
      routes = [ black ]
    when HANK_INGRAM
      routes = [ black, red ]
    end

    routes
  end
end
