
angular.module('skinnyBlog').controller 'AdminArticleController', [
  '$scope', '$timeout', '$stateParams', 'ApiService', 'ActivityService',
  ($scope,   $timeout,  $stateParams,  api,          activity) -> new class AdminArticleController
    constructor: ->
      window.feesh = @
      # Load the article
      promise = api.getArticle $stateParams.id
      activity.addPromise promise
      promise.success (data) =>
        @putArticleInScope data.article
      .error (data) ->
        # todo: Go to a 404 page
        console.log data

      @isSlugDirty = false

    updateSlug: (apply = false) ->
      update = =>
        @slug =  if not @isSlugDirty && @title && @publishedDate && !!@publishedDate.getFullYear()
          year = @publishedDate.getFullYear()
          month = '' + (@publishedDate.getMonth() + 1)
          month = '00'.substring(0, 2 - month.length) + month
          title = @title.replace(/[^a-z0-9 -]+/gi, '').replace(/\s+/g, '-').toLowerCase()
          "#{year}/#{month}/#{title}"
        else
          @slug

      if apply
        $timeout update
      else
        update()

    getSetText: (text = null) =>
      if text isnt null
        $timeout => @text = text
      else
        text

    putArticleInScope: (article) ->
      for property, value of article
        value = new Date(value) if property is 'publishedDate'
        @[property] = value
]