
angular.module('skinnyBlog').controller 'AdminDashboardController', [
  'ApiService',
  (api) -> new class AdminDashboardController
    constructor: ->
      @articles = null

      api.getArticles().success (data) =>
        @articles = data.articles
      .error =>
        @articles = false
]