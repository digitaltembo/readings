module StarRating
  def star_rating(stars)
    num_full_stars = stars.floor()
    num_half_stars = stars - num_full_stars >= 0.5 ? 1 : 0
    num_empty_stars = 5 - num_full_stars - num_half_stars
    
    title = case num_full_stars
    when 0
      "Not Rated"
    when 1
      "Didn't like it"
    when 2
      "It was OK"
    when 3
      "Liked it"
    when 4
      "Really liked it"
    when 5
      "Loved it"
    else
      "Huh!?"
    end

    html = String.new
    html += '<span class="rating" title="' + title + '">'

    if num_full_stars == 0
      html += '<i class="fa fa-question"></i>' * 3
    else
      num_full_stars.times do
        html += '<i class="fa fa-star"></i>'
      end

      num_half_stars.times do
        html += '<i class="fa fa-star-half-o"></i>'
      end

      num_empty_stars.times do
        html += '<i class="fa fa-star-o"></i>'
      end
    end

    html += '</span>'
    return html
  end
end

Liquid::Template.register_filter(StarRating)