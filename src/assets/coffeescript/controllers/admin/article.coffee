
angular.module('skinnyBlog').controller 'AdminArticleController', [
  '$scope', '$timeout', '$state', '$stateParams', 'ApiService', 'ActivityService',
  ($scope,   $timeout,   $state,   $stateParams,  api,          activity) -> new class AdminArticleController
    constructor: ->
      @saving = false
      @isSlugDirty = false
      @article = null

      # Load the article
      if $stateParams.id
        promise = api.getArticle $stateParams.id
        activity.addPromise promise
        promise.success (data) =>
          @article = data.article
          @article.publishedDate = new Date(@article.publishedDate)
          @isSlugDirty = @article.published
        .error (data) ->
          # todo: Add error alert
          $state.go 'admin'
      else
        @article =
          published:     false
          publishedDate: new Date()

    # Saves and publishes an article
    publish: ->
      @article.published = true
      @save true

    # Saves an article to the database
    save: (redirect = false) ->
      @saving = true

      promise = api.saveArticle @article
      activity.addPromise promise
      promise.success (data) =>
        @saving = false
        if redirect
          # todo: Add success message
          $state.go 'admin'
      .error (data) =>
        @saving = false
        # todo: Add error

    # Automatically updates the slug if we need to
    updateSlug: (apply = false) ->
      update = =>
        @article.slug =  if not @isSlugDirty && @article.title && @article.publishedDate && !!@article.publishedDate.getFullYear()
          year = @article.publishedDate.getFullYear()
          month = '' + (@article.publishedDate.getMonth() + 1)
          month = '00'.substring(0, 2 - month.length) + month
          title = @article.title.replace(/[^a-z0-9 -]+/gi, '').replace(/\s+/g, '-').toLowerCase()
          "#{year}/#{month}/#{title}"
        else
          @article.slug

      if apply
        $timeout update
      else
        update()

    # Getter/setter for the text
    articleText: (text = null) =>
      if text isnt null
        $timeout => @article.text = text
      else
        text
]