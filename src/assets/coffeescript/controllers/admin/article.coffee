
angular.module('skinnyBlog').controller 'AdminArticleController', [
  '$scope', '$timeout', '$state', '$stateParams', 'ApiService', 'AuthService', 'ActivityService', 'AlertService',
  ($scope,   $timeout,   $state,   $stateParams,   api,          auth,          activity,          alert) -> new class AdminArticleController
    constructor: ->
      @saving = false
      @isSlugDirty = false
      @article = null
      @pristineArticle = false

      # Load the article
      if $stateParams.id
        promise = api.getArticle $stateParams.id
        activity.addPromise promise
        promise.success (data) =>
          @article = data.article
          @article.publishedDate = new Date(@article.publishedDate)
          @isSlugDirty = @article.published
          @pristineArticle = angular.copy @article
        .error (data) ->
          alert.add "Alert id:#{$stateParams.id} not found."
          $state.go 'admin'
      else
        @article =
          published:     false
          publishedDate: new Date()
          tags:          []
        @pristineArticle = angular.copy @article

    # Saves and publishes an article
    publish: ->
      @article.published = true
      @save true

    # Saves an article to the database
    save: (redirect = false) ->
      @saving = true
      newArticle = !@article.id

      # If this is a new article, we need to use a different endpoint
      promise = if newArticle
        api.createArticle @article, auth.token
      else
        api.saveArticle @article, auth.token

      activity.addPromise promise
      promise.success (data) =>
        @saving = false

        if newArticle
          @article.id = data.article.id

        if redirect
          alert.add "Article \"#{@article.title}\" saved.", 'success'
          $state.go 'admin'
      .error (data) =>
        @saving = false
        alert.add 'Article could not be saved.'

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