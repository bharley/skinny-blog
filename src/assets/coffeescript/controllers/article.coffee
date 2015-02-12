
angular.module('skinnyBlog').controller 'ArticleController', [
  '$stateParams', 'ApiService', 'ActivityService',
  ($stateParams,   api,          activity) -> new class ArticleController
    constructor: ->
      promise = api.getArticle(
        $stateParams.year,
        $stateParams.month,
        $stateParams.title
      )
      activity.addPromise promise
      promise.success (data) =>
        @putArticleInScope data.article
      .error (data) ->
        # todo: Go to a 404 page
        console.log data

    putArticleInScope: (article) ->
      properties = ['title', 'text', 'publishedDate', 'slugParts', 'tags']
      @[property] = article[property] for property in properties
]