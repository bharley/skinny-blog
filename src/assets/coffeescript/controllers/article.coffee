
angular.module('skinnyBlog').controller 'ArticleController', [
  '$state', '$stateParams', '$sce', 'ApiService', 'ActivityService', 'Page',
  ($state,   $stateParams,   $sce,   api,          activity,          page) -> new class ArticleController
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
        @raw.html = $sce.trustAsHtml @raw.text
        @putArticleInScope()

        page.setTitle data.article.title
        page.setHeaderImage(data.article.headerImage) if data.article.headerImage
      .error ->
        $state.go '404'

    putArticleInScope: ->
      properties = ['title', 'html', 'publishedDate', 'slugParts', 'tags']
      @[property] = @raw[property] for property in properties
]