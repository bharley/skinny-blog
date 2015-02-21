
angular.module('skinnyBlog').controller 'ArticleController', [
  '$state', '$stateParams', 'ApiService', 'ActivityService', 'Page',
  ($state,   $stateParams,   api,          activity,          page) -> new class ArticleController
    constructor: ->
      promise = api.getArticle(
        $stateParams.year,
        $stateParams.month,
        $stateParams.title
      )
      activity.addPromise promise
      promise.success (data) =>
        @putArticleInScope data.article

        page.setTitle data.article.title
        page.setHeaderImage(data.article.headerImage) if data.article.headerImage
      .error ->
        $state.go '404'

    putArticleInScope: (article) ->
      properties = ['title', 'text', 'publishedDate', 'slugParts', 'tags']
      @[property] = article[property] for property in properties
]