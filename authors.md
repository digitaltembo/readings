---
layout: default
title: Authors
permalink: /authors
---

{% assign all_authors = '' | split: ',' %}

{% for post in site.posts %}
{% if post.author %}
{% assign all_authors = all_authors | push: post.author %}
{% endif %}
{% endfor %}
{% assign authors = all_authors | uniq | sort %}

<ul>
  {% for author in authors %}
    <li>{{ author }}</li>
    <ul>
      {% for post in site.posts %}
        {% if post.author == author %} 
          <li>
            <h3>
              <a class="post-link" href="{{ post.url | relative_url }}">
                {{ post.title | escape }}
              </a>
            </h3>
          </li>
        {% endif %}
      {% endfor %}
    </ul>
  {% endfor %}
</ul>
