
angular.module('skinnyBlog').controller 'ArticlesController', [
  '$stateParams', 'ApiService',
  ($stateParams,   api) -> new class ArticlesController
    constructor: ->
      @all = null

      console.log $stateParams
      promise = if $stateParams.tag
        @rawTag = $stateParams.tag
        @tag = $stateParams.tag.replace /-/g, ' '
        api.getArticlesWithTag $stateParams.tag
      else
        api.getArticles()

      promise.success (data) =>
        @all = data.articles
      .error (data) =>
        @all = false
]