require 'rubygems'
require 'json'
require 'sinatra/base'
require 'typhoeus'

class VandyVans < Sinatra::Base
  API_KEY = ENV['API_KEY']

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
            { '263473' => 'Branscomb Quad' },
            { '263470' => 'Carmichael Towers' },
            { '644903' => 'Hank Ingram' },
            { '1198824' => 'College Halls at Kissam' },
            { '263444' => 'Highland Quad' },
        ],
        other_stops: [
            { '264041' => 'Vanderbilt Police Department' },
            { '332298' => 'Vanderbilt Book Store' },
            { '644873' => '21st near Terrace Place' },
            { '1198825' => 'Wesley Place Garage' },
            { '263463' => 'North House' },
            { '264091' => 'Blair School of Music' },
            { '264101' => 'McGugin Center' },
            { '644874' => 'MRB 3' },
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
    when '263473', '263470', '263444' # Branscomb, Towers, or Highland
      routes = [ black, gold, red ]
    when '1178353', '644873' # Kissam or Terrace Place
      routes = [ black, gold ]
    when '264041' # VUPD
      routes = [ red, gold ]
    when '332298', '263463', '264091', '264101', '644874' # Book Store, North, Blair, McGugin, or MRB 3
      routes = [ gold ]
    when '238096' # Wesley
      routes = [ black ]
    when '644903' # Hank Ingram
      routes = [ black, red ]
    end

    routes
  end
end
