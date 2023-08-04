require 'open-uri'
require 'yaml'
require 'json'

module Jekyll
    # Location data is retrived from the nominatim OpenStreetmaps geocoding API, whose usage
    # should be sparing and attached to a specific email address
    EMAIL = "nolanhhawkins@gmail.com"
    # Nominatim doesn't like addresses that end in the continent, so let's filter those out from addresses
    CONTINENTS = ['North America', 'South America', 'Europe', 'Africa', 'Asia', 'Oceania', 'Central America']

    class MapTag < Liquid::Tag
        
        def initialize(tag_name, text, tokens)
            @config = Jekyll.configuration({})['mapping']
            @engine = @config['provider']
            @key = @config['api_key']
            if @config.has_key?('zoom')
                @zoom = @config['zoom']
            else
                @zoom = '10'
            end
            if text.empty?
                if @config['dimensions']
                    @width = @config['dimensions']['width']
                    @height = @config['dimensions']['height']
                else
                    @width = '600'
                    @height = '400'
                end
            else
                @width = text.split(",").first.strip
                @height = text.split(",").last.strip
            end
            super
        end

        def render(context)
            if context['page']['mapping']
                latitude = context['page']['mapping']['latitude']
                longitude = context['page']['mapping']['longitude']
                if @engine == 'google_static'
                    return "<img src=\"http://maps.googleapis.com/maps/api/staticmap?markers=#{latitude},#{longitude}&size=#{@width}x#{@height}&zoom=#{@zoom}&sensor=false\">"
                elsif (@engine == 'google_js' || @engine == 'openstreetmap')
                    return "<div id=\"jekyll-mapping\" style=\"height:#{@height}px;width:#{@width}px;\"></div>"
                end
            end
        end
    end

    class MapIndexTag < Liquid::Tag
        
        def initialize(tag_name, text, tokens)
            @data = Jekyll.configuration({})['mapping']
            @engine = @data['provider']

            @config = Jekyll.configuration({})['mapping']
            @engine = @config['provider']
            @key = @data['api_key']
            @categories = nil
            if @data['dimensions']
                @width = @data['dimensions']['width']
                @height = @data['dimensions']['height']
            else
                @width = '600'
                @height = '400'
            end
            if not text.empty?
                dimensions = text.split(":").first.strip
                cat = text.split(":").last.strip
                if not dimensions.empty?
                    @width = dimensions.split(",").first.strip
                    @height = dimensions.split(",").last.strip
                end
                if not cat.empty?
                    @categories = []
                    for c in cat.split(",")
                        @categories << c
                    end
                end
            end
            super
        end
        
        def render(context)
            posts = []
            if @categories
                for cat in @categories
                    for post in context.registers[:site].categories[cat]
                        posts << post
                    end
                end
            else
                posts = context.registers[:site].posts
            end
            @data['pages'] = []
            for post in posts
                if post.data["mapping"] && (
                    post.data['mapping'].is_a?(String) ||
                    (post.data['mapping'].has_key?('latitude') && post.data['mapping'].has_key?('longitude'))
                )
                    postinfo = post.data.clone()
                    if Jekyll.configuration({})['baseurl']
                        pogstinfo['link'] = "#{Jekyll.configuration({})['baseurl']}#{post.url.chars.first == "/" ? post.url[1..-1] : post.url}"
                    else
                        postinfo['link'] = post.url
                    end
                    if post.data['mapping'].is_a?(String) && lookup_location(postinfo, context.registers[:site], post.data['mapping'])
                      @data['pages'] << postinfo
                    else
                      postinfo['latitude'] = post.data['mapping']['latitude']
                      postinfo['longitude'] = post.data['mapping']['longitude']
                      @data['pages'] << postinfo
                    end
                end
            end

            if (@engine == 'google_js')
                return "
                    <div id='jekyll-mapping' style='height:#{@height}px;width:#{@width}px;'>
                    </div>
                    <script type='text/javascript'>
                        window.onload = function () { jekyllMapping.loadScript(#{@data.to_json}); };
                    </script>
                    "
            end   
            if (@engine == 'openstreetmap')
                return "
                    <div id='jekyll-mapping' style='height:#{@height}px;width:#{@width}px;'>
                    </div>
                    <script type='text/javascript'>
                        window.onload = function () { jekyllMapping.mappingInitialize(#{@data.to_json}); };
                    </script>
                    "
            end         
        end

        # adds the lat/long position data to the postinfo given the location.yml data hierarchy
        def lookup_location(postinfo, site, location)
            location_iter = site.data["locations"]
            name_iter = ''
            for place in location.split(',').reverse()
                place = place.strip()
                foundLocation = false
                location_iter.each do |key, value| 
                    if key == place || (value.is_a?(Hash) && value.has_key?('aliases') && value['aliases'].include?(place))
                        location_iter = value
                        foundLocation = true
                        break
                    end
                end
                if !foundLocation
                    location_iter[place] = {}
                    location_iter = location_iter[place]
                end
                name_iter = CONTINENTS.include?(name_iter) || name_iter == '' ? place:  place + ', ' + name_iter

                if !location_iter.has_key?('latitude')
                    add_location(location_iter, name_iter, site.data["locations"])
                end
            end
            if location_iter.has_key?('latitude') && location_iter.has_key?('longitude')
                postinfo['latitude'] = location_iter['latitude']
                postinfo['longitude'] = location_iter['longitude']
                return true
            end
            return false
        end

        # adds the lat/long position of a location by name using the nominatim geocoding api
        def add_location(loc_data, name, all_locations)
            results = JSON.parse(URI.open(
                "https://nominatim.openstreetmap.org/search?email=#{EMAIL}&format=json&q=" + name,
                "User-Agent" => "jekyll-maps.rb/#{EMAIL}"
            ).read)
            
            if results && results[0] && results[0].has_key?('lat') && results[0].has_key?('lon')
                puts "Found location #{name} #{results[0]}"
                loc_data['latitude'] = results[0]['lat']
                loc_data['longitude'] = results[0]['lon']
                File.write(Dir.pwd + '/_data/locations.yml', all_locations.to_yaml)
            else
                puts "Did not find location #{name}"
            end
            # Usage of the nominatim API should be limited to no more than one query per second
            # Sleep for 2 to be extra gentle
            sleep(2)
        end
    end
end

Liquid::Template.register_tag('render_map', Jekyll::MapTag)
Liquid::Template.register_tag('render_index_map', Jekyll::MapIndexTag)
