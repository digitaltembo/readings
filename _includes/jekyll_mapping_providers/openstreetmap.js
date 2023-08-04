<script type="text/javascript">
var jekyllMapping = (function () {
    'use strict';
    var settings;
    var obj = {
        plotArray: function(locations) {
            const group = new L.featureGroup();
            const markers = L.markerClusterGroup({
              maxClusterRadius: 40
            });
            while (locations.length > 0) {
                const loc = locations.pop();
                console.log(loc);
                const m =  L.marker([loc.latitude, loc.longitude])
                markers.addLayer(m);
                m
                  .addTo(group)
                  .bindPopup(loc.marker_content);
            }
            this.map.addLayer(markers);
            console.log(this.markers,group.getBounds());
            this.map.fitBounds(group.getBounds());
        },
        indexMap: function () {
            this.plotArray(settings.pages);
        },
        pageToMap: function () {
            if (typeof(settings.latitude) !== 'undefined' && typeof(settings.longitude) !== 'undefined') {
                const m = L.marker([settings.latitude, settings.longitude]);
                this.map.setView(m, settings.zoom);
            }     

            if (settings.locations instanceof Array) {
                this.plotArray(settings.locations);
            }
            
 
        },
        mappingInitialize: function (set) {
            settings = set;
            this.map =  L.map('jekyll-mapping');
            L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '© OpenStreetMap'
            }).addTo(this.map);
            this.markers = [];

            if (settings.pages) {
                this.indexMap();
            } else {
                this.pageToMap();
            }
        }        
    };
    return obj;
}());
</script>
