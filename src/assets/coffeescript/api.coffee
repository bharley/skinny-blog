
angular.module('skinnyBlog').factory 'ApiService', [
  '$http', '$cacheFactory', '$q',
  ($http,   $cacheFactory,   $q) -> new class ApiService
    # Angular's $http cache is very iffy, so we'll just use the cache factory
    constructor: -> @cache = $cacheFactory 'apiServiceCache'

    # Fetches all of the articles and caches each individual one
    getArticles: ->
      @cacheOrPerform 'articles', =>
        deferred = $q.defer()

        $http.get('/api/articles').success (data) =>
          for article in data.articles
            @cache.put "article:#{article.slug}",
              article: article
          deferred.resolve data
        .error (data) ->
          deferred.reject data

        return deferred.promise

    # Gets a single article
    getArticle: (slugOrYear, month = null, title = null) ->
      slug = if month isnt null && title isnt null
        "#{slugOrYear}/#{month}/#{title}"
      else
        slugOrYear

      @cacheOrPerform "article:#{slug}", ->
        $http.get "/api/articles/#{slug}"

    # Helper method for grabbing something from the cache if it's there
    cacheOrPerform: (key, fn) ->
      value = @cache.get key
      if value is undefined
        value = fn()
        @cache.put key, value
      return value
]