var _ = require('underscore.js')

Parse.Cloud.define("arrivalTimes", function(request, response) {
	var stopID = request.params.stopID;
	
	var predictionsResponse = [ ];
	var promises = [ ];
	
	var requestPredictions = function() {
		_.each([ 745, 746, 749 ], function(routeID) {
			promises.push(Parse.Cloud.httpRequest({
				url: 'http://api.syncromatics.com/Route/' + routeID + '/Stop/' + stopID + '/Arrivals?api_key=a922a34dfb5e63ba549adbb259518909',
				success: function(httpResponse) {
					var data = httpResponse.data;
					var predictions = data['Predictions'];
		
					if (predictions.length == 0) {
						console.log('No predictions for ' + routeID);
					} else {
						predictions.forEach(function(prediction) {
							predictionsResponse[predictionsResponse.length] = { 'StopID' : prediction['StopId'], 'RouteID' : prediction['RouteId'], 'Minutes' : prediction['Minutes'] };
						});
					}
				},
				error: function(httpResponse) {
					console.error('Request failed with response code ' + httpResponse.status);
					response.error('VandyVans.com appears to be unavailable.');
				}
			}));
		});	
		
		return Parse.Promise.when(promises);
	};
	
	requestPredictions().then(function() {
		response.success(predictionsResponse);
	});
});

Parse.Cloud.define("arrivalTimesTest", function(request, response) {
	var stopID = request.params.stopID;
	
	var predictionsResponse = [ ];
	var promises = [ ];
	
	var requestPredictions = function() {
		_.each([ 745, 746, 749 ], function(routeID) {
			promises.push(Parse.Cloud.httpRequest({
				url: 'http://api.syncromatics.com/Route/' + routeID + '/Stop/' + stopID + '/Arrivals?api_key=a922a34dfb5e63ba549adbb259518909',
				success: function(httpResponse) {
					if (routeID == 745) {
						predictions = [ { 'StopId' : stopID, 'RouteId' : routeID, 'Minutes' : 2 }, { 'StopId' : stopID, 'RouteId' : routeID, 'Minutes' : 4 } ]
					} else if (routeID == 746) {
						predictions = [ { 'StopId' : stopID, 'RouteId' : routeID, 'Minutes' : 10 } ]
					} else {
						predictions = [ { 'StopId' : stopID, 'RouteId' : routeID, 'Minutes' : 6 } ]
					}
					
					if (predictions.length == 0) {
						console.log('No predictions for ' + routeID);
					} else {
						predictions.forEach(function(prediction) {
							predictionsResponse[predictionsResponse.length] = { 'stopID' : prediction['StopId'], 'routeID' : prediction['RouteId'], 'minutes' : prediction['Minutes'] };
						});
					}
				},
				error: function(httpResponse) {
					console.error('Request failed with response code ' + httpResponse.status);
					response.error('VandyVans.com appears to be unavailable.');
				}
			}));
		});	
		
		return Parse.Promise.when(promises);
	};
	
	requestPredictions().then(function() {
		predictionsResponse.sort(function(a, b) {
			return a.minutes - b.minutes;
		});
		
		response.success(predictionsResponse);
	});
});