vandyvans-backend
=================

A [Sinatra](http://www.sinatrarb.com/) backend for Vandy Vans clients.

The Sinatra app has 4 endpoints, all at the base URL (http://default-environment-pkuc3jhwtp.elasticbeanstalk.com):

## Arrival Times

List the arrival times for a specific stop.

**Request**
```
GET /arrivalTimes
```

**Parameters**

`stopID` (string) - ID for a particular Vandy Van stop. Returns an empty array if left blank.

**Response**
```
[
  {
    "stopID": 263473,
    "routeID": 1857,
    "minutes": 3
  }
]
```

## Vans

List the active vans for a specific route.

**Request**
```
GET /vans
```

**Parameters**
`routeID` (string) - ID for a particular Vandy Van route. Returns an empty array if left blank.

**Response**
```
[
  {
    "vanID": 530,
    "latitude": 36.14879,
    "longitude": -86.804073,
    "percentageFull": 24
  }
]
```

## Waypoints

List the waypoints for a route in order to build a polyline on a map.

**Request**
```
GET /waypoints
```

**Parameters**
`routeID` (string) - ID for a particular Vandy Van route. Returns an empty array if left blank.

**Response**
```
[
  {
    "latitude": 36.1453887419637,
    "longitude": -86.80566340684891
  },
  {
    "latitude": 36.145828427596065,
    "longitude": -86.80489897727966
  },
  {
    "latitude": 36.1472839210716,
    "longitude": -86.8059504032135
  }
]
```

## Stops

List the stop IDs and stops that should be displayed in the app.

**Request**
```
GET /stops
```

**Parameters**
None.

**Response**
```
{
  "stops":
    [
      "245678": "Branscomb Quad",
      "256789": "Carmichael Towers"
    ],
  "otherStops":
    [
      "234566": "VUPD"
    ]
}
```

## Deploying the App

Please contact [Seth Friedman](mailto:sethfri@gmail.com) if you would like to update and redeploy the app. It requires getting the credentials to the AWS account, which obviously can't be posted here.
