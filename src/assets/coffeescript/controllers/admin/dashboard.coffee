angular.module('skinnyBlog').controller 'AdminDashboardController', [
  'ApiService', 'ActivityService', 'AuthService',
  (api,          activity,          auth) -> new class AdminDashboardController
    constructor: ->
      @articles = null

      promise = api.adminGetArticles(auth.token)
      activity.addPromise promise
      promise.success (data) =>
        @articles = data.articles
      .error =>
        @articles = false

    deleteArticle: (index) ->
      if window.confirm 'Are you sure you want to delete this article?'
        article = @articles[index]
        promise = api.adminDeleteArticle article.id, auth.token
        promise.success =>
          @articles.splice index, 1
        .error (data) ->
          # todo: Display this
          console.log 'Error'
]