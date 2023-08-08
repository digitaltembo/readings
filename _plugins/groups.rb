module SamplePlugin
  class CategoryPageGenerator < Jekyll::Generator
    safe true
    
    def generate(site)
      make_cat(site, 'author') {|post| post.data["author"]}
      make_cat(site, 'stars') {|post| (post.data["stars"] || 0).to_s}
      make_cat(site, 'tags') {|post| post.data["tags"]}
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
      distinct_cats.each do |cat|
        posts = site.posts.docs.select do |post| 
          cats = categorizer.call(post)
          cats.is_a?(Array) ? (cats.include? cat) : cats == cat
        end 
        site.pages << GroupPage.new(site, cat_name, cat.gsub(' ', '-'), posts)
      end
    end
  end

  # Subclass of `Jekyll::Page` with custom method definitions.
  class GroupPage < Jekyll::Page
    def initialize(site, type, group, posts)
      @site = site               # the current site instance.
      @base = site.source        # path to the source directory.
      @dir  = "#{type}/#{group}" # the directory the page will reside in.

      # All pages have the same filename, so define attributes straight away.
      @basename = 'index'      # filename without the extension.
      @ext      = '.html'      # the extension.
      @name     = 'index.html' # basically @basename + @ext.

      # Initialize data hash with a key pointing to all posts under current group.
      # This allows accessing the list in a template via `page.linked_docs`.
      @data = {
        'linked_docs' => posts
      }

      # Look up front matter defaults scoped to type `groups`, if given key
      # doesn't exist in the `data` hash.
      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :groups, key)
      end
    end

    # Placeholders that are used in constructing page URL.
    def url_placeholders
      puts @dir
      {
        :path       => @dir,
        :category   => @dir,
        :basename   => basename,
        :output_ext => output_ext,
      }
    end
  end
end