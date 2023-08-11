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

<ul class="tree" style="columns: 2;">
  {% for author in authors %}
    <li>
      <details>
        <summary><a href="/author/{{author | simple_slug }}">{{ author }}</a></summary>
        <ul>
          {% for post in site.posts %}
            {% if post.author == author %} 
              <li>
                <a class="post-link" href="{{ post.url | relative_url }}">
                  {{ post.title | escape }}
                </a>
              </li>
            {% endif %}
          {% endfor %}
        </ul>
      </details>
    </li>
  {% endfor %}
</ul>
