
angular.module('skinnyBlog').controller 'ArticleController', [
  '$stateParams', 'ApiService',
  ($stateParams,   api) -> new class ArticleController
    constructor: ->
      api.getArticle(
        $stateParams.year,
        $stateParams.month,
        $stateParams.title
      ).success (data) =>
        @putArticleInScope data.article
      .error (data) ->
        # todo: Go to a 404 page
        console.log data

    putArticleInScope: (article) ->
      @title = article.title
      @text = article.text
]