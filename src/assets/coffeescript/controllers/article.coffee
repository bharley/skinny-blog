
angular.module('skinnyBlog').controller 'ArticleController', [
  '$state', '$stateParams', 'ApiService', 'ActivityService', 'Page',
  ($state,   $stateParams,   api,          activity,          page) -> new class ArticleController
    constructor: ->
      @raw = null
      @showComments = true

      promise = api.getArticle(
        $stateParams.year,
        $stateParams.month,
        $stateParams.title
      )
      activity.addPromise promise
      promise.success (data) =>
        @raw = data.article
        @putArticleInScope()
        page.setTitle data.article.title
      .error ->
        $state.go '404'

    putArticleInScope: ->
      properties = ['title', 'text', 'publishedDate', 'slugParts', 'tags']
      @[property] = @raw[property] for property in properties
]