
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
          @cacheArticles data.articles
          deferred.resolve data
        .error (data) ->
          deferred.reject data

        return deferred.promise

    # Fetches all of the articles with the given tag
    getArticlesWithTag: (tag) ->
      @cacheOrPerform "articles tag:#{tag}", =>
        deferred = $q.defer()

        $http.get('/api/articles?tag=' + tag).success (data) =>
          @cacheArticles data.articles
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

    cacheArticles: (articles) ->
      for article in articles
        # Create a promise so that this meets the same API contract as getting a single article
        articleDeferred = $q.defer()
        articleDeferred.resolve(article: article)
        @cache.put "article:#{article.slug}", articleDeferred.promise

    # Gets all of the articles for the admin dashboard
    adminGetArticles: ->
      @cacheOrPerform 'admin articles', ->
        $http.get '/api/articles/all'

    # Deletes an article
    adminDeleteArticle: (id) ->
      $http.delete "/api/articles/#{id}"

    # Helper method for grabbing something from the cache if it's there
    cacheOrPerform: (key, fn) ->
      value = @cache.get key
      if value is undefined
        value = fn()
        @cache.put key, value
      return value
]