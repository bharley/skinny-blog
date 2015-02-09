
angular.module('skinnyBlog').controller 'ArticlesController', [
  '$stateParams', 'ApiService', 'ActivityService',
  ($stateParams,   api,          activity) -> new class ArticlesController
    constructor: ->
      @all = null

      promise = if $stateParams.tag
        @rawTag = $stateParams.tag
        @tag = $stateParams.tag.replace /-/g, ' '
        api.getArticlesWithTag $stateParams.tag
      else
        api.getArticles()

      activity.addPromise promise
      promise.success (data) =>
        @all = data.articles
      .error (data) =>
        @all = false
]