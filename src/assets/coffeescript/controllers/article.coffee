
angular.module('skinnyBlog').controller 'ArticleController', [
  '$state', '$stateParams', 'ApiService', 'ActivityService',
  ($state,   $stateParams,   api,          activity) -> new class ArticleController
    constructor: ->
      promise = api.getArticle(
        $stateParams.year,
        $stateParams.month,
        $stateParams.title
      )
      activity.addPromise promise
      promise.success (data) =>
        @putArticleInScope data.article
      .error ->
        $state.go '404'

    putArticleInScope: (article) ->
      properties = ['title', 'text', 'publishedDate', 'slugParts', 'tags']
      @[property] = article[property] for property in properties
]