module Jekyll
  class LocationTree < Liquid::Tag
    BASE_TREE = {:count => 0, :children => {}}
    def render_location(loc)
      link = "<a href='#{loc[:url]}'>#{loc[:name]} (#{loc[:count]})</a>"
      if loc[:children].size > 0
        return <<~HTML
        <li>
          <details #{loc[:url] == "/" ? "open" : ""}>
            <summary>#{link}</summary>
            <ul>
              #{loc[:children].each_value.sort_by{|loc| -loc[:count]}.map(&method(:render_location)).join}
            </ul>
          </details>
        </li>
        HTML
      else
        return "<li>#{link}</li>"
      end
    end
      
    def render(context)
      location_tree = context.registers[:site].posts.docs.reduce({:name => 'World', :url => '/', :count => 0, :children => {}}){|tree,post| 
        tree[:count] += 1
        if post.data["mapping"]
          iter = tree
          url = '/loc/'
          post.data["mapping"].split(",").reverse.each do |loc|
            loc = loc.strip()
            url += loc.gsub(' ', '-').gsub('.', '') + '/'
            if !iter[:children].has_key?(loc)
              iter[:children][loc] = {:name => loc, :url => url, :count => 0, :children => {}}
            end
            iter = iter[:children][loc]
            iter[:count] += 1
          end
          tree
        end
        tree
      }

      return render_location(location_tree)

    end
  end
end

Liquid::Template.register_tag('location_tree', Jekyll::LocationTree)