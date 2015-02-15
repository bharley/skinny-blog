
angular.module('skinnyBlog').controller 'ArticlesController', [
  '$state', 'ApiService', 'ActivityService',
  ($state,   api,          activity) -> new class ArticlesController
    constructor: ->
      @prevHref = null
      @nextHref = null

      @all = null
      @pages = null

      params = $state.params
      # Get the page if we have one
      @page = if params.page && params.page >= 1
        parseInt params.page
      else
        1

      # Placeholders for navigation
      @nextPage = @page
      @previousPage = @page

      # Get the tag if we have one
      @tag = if params.tag
        @rawTag = params.tag
        params.tag.replace /-/g, ' '
      else
        null

      # Perform the API request
      promise = api.getArticles @page, @tag
      activity.addPromise promise
      promise.success (data) =>
        @all = data.articles

        if data.meta.pages && data.meta.pages > 1
          @pages = data.meta.pages

          state = if @tag then 'tag' else 'articles'
          params = if @tag then {tag: @rawTag} else {}

          # Set up the previous href if it's valid
          if @page < @pages
            @prevHref = $state.href state + '/page', $.extend({}, params, page: @page + 1)

          # Set up the next href
          if @page is 2
            @nextHref = $state.href state, params
          else if @page > 2
            @nextHref = $state.href state + '/page', $.extend({}, params, page: @page - 1)
      .error (data) =>
        @all = false

    # Goes home if we're in a tag search
    closeTagSearch: ->
      if @tag
        $state.go 'articles'
]