module Jekyll
  class TimeTree < Liquid::Tag
    BASE_TREE = {:count => 0, :children => {}}
    def render_date(date)
      link = "<a href='#{date[:url]}'>#{date[:name]} (#{date[:count]})</a>"
      if date[:children].size > 0
        return <<~HTML
        <li>
          <details #{date[:url] == "/" ? "open" : ""}>
            <summary>#{link}</summary>
            <ul>
              #{date[:children].each_value.sort_by{|child_date| child_date[:sort]}.map(&method(:render_date)).join}
            </ul>
          </details>
        </li>
        HTML
      else
        return "<li>#{link}</li>"
      end
    end
      
    def render(context)
      time_tree = context.registers[:site].posts.docs.reduce({
        :name => 'Books with Publication Times',
        :url => '/',
        :count => 0,
        :children => {},
        :sort => 0
      }) {|tree,post| 
        if post.data["written"]
          tree[:count] += 1
          iter = tree
          url = '/date/'
          written = post.data["written"]
          dates = [
            [written / 100 + 1, "#{written / 100 + 1}c.", "/date/#{written / 100 + 1}c"], 
            [(written / 10) * 10, "#{(written / 10) * 10}s", "/date/#{(written / 10) * 10}s" ], 
            [written, written.to_s, "/date/#{written}"],
            [written, post.data["title"], post.url],
          ]

          dates.each do |date, name, url|
            if !iter[:children].has_key?(name)
              iter[:children][name] = {
                :name => name,
                :url => url, 
                :count => 0,
                :children => {}, 
                :sort => date
              }
            end
            iter = iter[:children][name]
            iter[:count] += 1
          end
          tree
        end
        tree
      }

      return render_date(time_tree)

    end
  end
end

Liquid::Template.register_tag('time_tree', Jekyll::TimeTree)