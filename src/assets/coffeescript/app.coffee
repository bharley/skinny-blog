
app = angular.module('skinnyBlog', ['ui.router']).config [
  '$stateProvider', '$urlRouterProvider', '$locationProvider', '$provide',
  ($stateProvider,   $urlRouterProvider,   $locationProvider,   $provide) ->
    # Turn on HTML5 url mode
    $locationProvider.html5Mode true

    # Set up our states/routes
    $stateProvider
      # List of articles
      .state 'articles',
        url:          '^/'
        templateUrl:  'partials/articles.html'
        controller:   'ArticlesController as articles'

      # Lists articles with the given tag
      .state 'tag',
        url:          '^/tag/:tag'
        templateUrl:  'partials/articles.html'
        controller:   'ArticlesController as articles'

      # Single article view
      .state 'article',
        url:          '^/{year:[0-9]{4}}/{month:[0-9]{2}}/:title'
        templateUrl:  'partials/article.html'
        controller:   'ArticleController as article'

    # Adds the 'success' and 'error' convenience methods that the $http promises have
    $provide.decorator '$q', [
      '$delegate',
      ($delegate) ->
        defer = $delegate.defer

        $delegate.defer = ->
          deferred = defer()

          deferred.promise.success = (fn) ->
            deferred.promise.then fn
            return deferred.promise

          deferred.promise.error = (fn) ->
            deferred.promise.then null, fn
            return deferred.promise

          return deferred

        return $delegate
    ]
]