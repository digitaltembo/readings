require 'enumerator'

module Groups
  def simple_slug(text)
    text.gsub(' ', '-').gsub('.', '')
  end
  
  class CategoryPageGenerator < Jekyll::Generator
    safe true
    
    def generate(site)
      make_cat(site, 'author') {|post| post.data["author"]}
      make_cat(site, 'stars') {|post| (post.data["stars"] || 0).to_s}
      make_cat(site, 'tags') {|post| post.data["tags"]}
      make_cat(site, 'language') {|post| post.data["translatedFrom"]}
      make_cat(site, 'date') do |post|
        if post.data["written"]
          d = post.data["written"]
          ["#{d / 100 + 1}c", "#{(d / 10) * 10}s", d.to_s]
        else
          []
        end
      end
      make_cat(site, 'loc') do |post|
        if post.data["mapping"]
          locs = post.data["mapping"].split(",").reverse.filter_map{|l| l.strip()}
          (0..locs.length - 1).map{|i| (0..i).map{|j| locs[j]}.join("/")}
        else
          []
        end
      end

      auth_gender = {}
      site.posts.docs.each do |post|
        if post.data["gender"] && ! auth_gender.has_key?(post.data["author"])
          auth_gender[post.data["author"]] = post.data["gender"]
        end
      end
      make_cat(site, 'tags') do |post|
        case auth_gender[post.data['author']]
        when 'm'
          'male-author'
        when 'f'
          'female-author'
        else
          'unknown-gender'
        end
      end
    end

    def make_cat(site, cat_name, &categorizer)
      distinct_cats = []
      site.posts.docs.each do |post|
        cats = categorizer.call(post)
        if cats
          if ! cats.is_a? Array
            cats = [cats]
          end
          cats.each do |cat|
            if !distinct_cats.include?(cat)
              distinct_cats.push(cat)
            end
          end
        end
      end
      per_page = 10
      distinct_cats.each do |cat|
        posts = site.posts.docs.select do |post| 
          cats = categorizer.call(post)
          cats.is_a?(Array) ? (cats.include? cat) : cats == cat
        end

        posts.sort_by{|post|post.data["date"]}.reverse.each_slice(per_page).with_index do |paginated_posts, index| 
          total_pages = (posts.length.to_f / per_page).ceil


          site.pages << GroupPage.new(site, cat_name, cat, {
            'page' => index + 1,
            'per_page' => per_page,
            'posts' => paginated_posts,
            'total_posts' => posts.length(),
            'total_pages' => total_pages,
            'previous_page' => index > 1 ? index : nil,
            'next_page' => index < (total_pages - 2) ? index + 2 : nil
          })
        end
      end
    end
  end

  # Subclass of `Jekyll::Page` with custom method definitions.
  class GroupPage < Jekyll::Page
    include Groups
    PAGE_LINK_DELTA_COUNT = 3
    def page_path(page)
      if page == 1
        return 'index'
      else
        return "#{page}"
      end
    end
    
    def initialize(site, type, group, pagination)
      @site = site               # the current site instance.
      @base = site.source        # path to the source directory.
      # @dir  = "#{type}/#{group.gsub(' ', '-').gsub('.', '')}#{pagination['page'] > 0 ? '/' + pagination['page'].to_s : ''}" # the directory the page will reside in.
      @dir  = "#{type}/#{simple_slug(group)}/" # the directory the page will reside in.

      # All pages have the same filename, so define attributes straight away.
      @basename = page_path(pagination["page"])# 'index'   # filename without the extension.
      @ext      = '.html'          # the extension.
      @name     = @basename + @ext

      if pagination['next_page']
        pagination['next_page_path'] = page_path(pagination['next_page']) + @ext
      end
      
      if pagination['previous_page']
        pagination['previous_page_path'] = page_path(pagination['previous_page']) + @ext
      end

      links = (1..pagination["total_pages"]).map do |page|
        if page == pagination["page"]
          {"current" => page }
        elsif page == 1 || page == pagination["total_pages"] || (pagination["page"] - page).abs < PAGE_LINK_DELTA_COUNT
          {"url" => page_path(page) + @ext, "label" => page}
        else
          "..."
        end
      end
      pagination["page_links"] = links.filter_map.with_index {|link, i| 
        link if !(link == "..." && links[i - 1] == "...")
      }



      
      # Initialize data hash with a key pointing to all posts under current group.
      # This allows accessing the list in a template via `page.linked_docs`.
      @data = {
        'title' => group,
        'paginator' => pagination
      }

      # Look up front matter defaults scoped to type `groups`, if given key
      # doesn't exist in the `data` hash.
      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :groups, key)
      end
    end

    # Placeholders that are used in constructing page URL.
    def url_placeholders
      {
        :path       => @dir,
        # :category   => @dir + @name,
        :basename   => basename,
        :output_ext => output_ext,
      }
    end
  end
end

Liquid::Template.register_filter(Groups)