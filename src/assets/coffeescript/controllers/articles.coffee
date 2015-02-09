
angular.module('skinnyBlog').controller 'ArticlesController', [
  'ApiService',
  (api) -> new class ArticlesController
    constructor: ->
      @all = null
      api.getArticles().success (data) =>
        @all = data.articles
      .error (data) =>
        @all = false
]