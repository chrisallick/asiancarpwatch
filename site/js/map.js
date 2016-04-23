// return station ID + distance
// input station ID
// enter phone number
// return station lat/lon
// click map to calculate distance
// confirm location
// submit


// 43.141722, -77.616306
var stationLat = 43.141722;
var stationLon = -77.616306;
var stationLocation = new google.maps.LatLng( stationLat, stationLon );

var mapCenter = new google.maps.LatLng(45.96642454131025, -84.287109375);

// custom marker image
var markerImage = {
	url     : 'marker.png',
	size    : new google.maps.Size(30, 30),
	origin  : new google.maps.Point(0, 0),
	anchor  : new google.maps.Point(0, 30)
};

// customize map appearance
var mapStyles = [
				{
						"elementType": "labels.icon",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "landscape",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "poi",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "road.highway",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "road.arterial",
						"stylers": [
								{
										"visibility": "simplified"
								}
						]
				},
				{
						"featureType": "road.arterial",
						"elementType": "labels.icon",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "road.arterial",
						"elementType": "labels.text.stroke",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "road.arterial",
						"elementType": "labels.text.fill",
						"stylers": [
								{
										"visibility": "simplified"
								}
						]
				},
				{
						"featureType": "road.local",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "transit",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "administrative",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "administrative.neighborhood",
						"elementType": "labels",
						"stylers": [
								{ "visibility": "off" }
						]
				},
				{
						"featureType": "water",
						"elementType": "labels",
						"stylers": [
								{
										"visibility": "off"
								}
						]
				},
				{
						"featureType": "water",
						"elementType": "geometry",
						"stylers": [
								{
										"hue": "#ffff00"
								},
								{
										"lightness": -25
								},
								{
										"saturation": -97
								}
						]
				}
		];

function init() {

	// https://developers.google.com/maps/documentation/javascript/reference#MapOptions
	var mapOptions = {
			zoom: 10,
			center: mapCenter,
			disableDefaultUI: true,
			// styles: mapStyles
	};

	var mapElement = document.getElementById('map');

	var map = new google.maps.Map(mapElement, mapOptions);

	placeMarker( map, stationLocation );

	google.maps.event.addDomListener(map, 'click', function(event){
		var newLocation = event.latLng;
		placeMarker( map, newLocation );
		console.log( newLocation.lat(), newLocation.lng() )
		console.log( distance( stationLat, stationLon, newLocation.lat(), newLocation.lng(), 'M' ) );
	});

} 

function placeMarker(map,coords) {
	var marker = new google.maps.Marker({
		position : coords,
		map : map,
		icon : markerImage
	});
}

// https://www.geodatasource.com/developers/javascript
function distance(lat1, lon1, lat2, lon2, unit) {
	var radlat1 = Math.PI * lat1/180
	var radlat2 = Math.PI * lat2/180
	var theta = lon1-lon2
	var radtheta = Math.PI * theta/180
	var dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);
	dist = Math.acos(dist)
	dist = dist * 180/Math.PI
	dist = dist * 60 * 1.1515
	if (unit=="K") { dist = dist * 1.609344 }
	if (unit=="N") { dist = dist * 0.8684 }
	return dist
}

// When the window has finished loading create our google map below
google.maps.event.addDomListener(window, 'load', init);









