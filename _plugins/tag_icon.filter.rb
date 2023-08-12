module TagIcon
  def tag_icons(tags)
    tags.map {|tag|
      case tag
      when "listened"
        "headphones"
      when "read"
        "book"
      when "mystery"
        "search"
      when "scifi"
        "rocket"
      when "fantasy"
        "hat-wizard"
      when "non-fiction"
        "earth-americas"
      when "historical"
        "landmark"
      when "adventure"
        "mountain"
      when "sailing"
        "sailboat"
      else
        nil
      end
    }.zip(tags).filter_map {|icon, tag| "<i class='fa fa-solid fa-#{icon}' title='#{tag}'></i>" if icon}
  end
end

Liquid::Template.register_filter(TagIcon)