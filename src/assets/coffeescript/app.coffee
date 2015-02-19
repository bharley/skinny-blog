
app = angular.module('skinnyBlog', ['ngCookies', 'ui.router']).config [
  '$stateProvider', '$urlRouterProvider', '$urlMatcherFactoryProvider', '$locationProvider', '$provide',
  ($stateProvider,   $urlRouterProvider,   $urlMatcherFactoryProvider,   $locationProvider,   $provide) ->
    # Turn on HTML5 url mode
    $locationProvider.html5Mode true

    # Allow matching with slashes at the end of a URL
    $urlMatcherFactoryProvider.strictMode false

    # 404 on missing pages
    $urlRouterProvider.otherwise ($injector, $location) ->
      $injector.invoke [
        '$state',
        ($state) ->
          $state.go '404'
      ]

    # Set up our states/routes
    $stateProvider
      # List of articles
      .state 'articles',
        url:         '^/'
        templateUrl: 'partials/articles.html'
        controller:  'ArticlesController as articles'

      # List of articles, paginated
      .state 'articles/page',
        url:         '^/page/{page:[1-9][0-9]*}'
        templateUrl: 'partials/articles.html'
        controller:  'ArticlesController as articles'

      # Lists articles with the given tag
      .state 'tag',
        url:         '^/tag/:tag'
        templateUrl: 'partials/tag.html'
        controller:  'ArticlesController as articles'

      # Lists articles with the given tag
      .state 'tag/page',
        url:         '^/tag/:tag/page/{page:[1-9][0-9]*}'
        templateUrl: 'partials/tag.html'
        controller:  'ArticlesController as articles'

      # Single article view
      .state 'article',
        url:         '^/{year:[0-9]{4}}/{month:[0-9]{2}}/:title'
        templateUrl: 'partials/article.html'
        controller:  'ArticleController as article'

      # Admin - dashboard
      .state 'admin',
        url:         '^/admin'
        templateUrl: 'partials/admin/dashboard.html'
        controller:  'AdminDashboardController as dashboard'
        options:
          secure: true
          title:  'Admin'

      # Admin - Edit an article
      .state 'admin/article',
        url:         '^/admin/articles/{id:[0-9]+}'
        templateUrl: 'partials/admin/article.html'
        controller:  'AdminArticleController as admin'
        options:
          secure: true
          title:  'Admin'

      # Admin - Create an article
      .state 'admin/article/new',
        url:         '^/admin/articles/new'
        templateUrl: 'partials/admin/article.html'
        controller:  'AdminArticleController as admin'
        options:
          secure: true
          title:  'Admin'

      # Admin - Create an article
      .state 'admin/login',
        url:         '^/admin/login'
        templateUrl: 'partials/admin/login.html'
        controller:  'AdminLoginController as login'
        options:
          title: 'Log In'

      # 404 state
      .state '404',
        templateUrl: 'partials/404.html'
        options:
          title: 'Page not found'

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

app.run [
  '$rootScope', '$state', 'ActivityService', 'AuthService', 'Page',
  ($rootScope,   $state,   activity,          auth,          page) ->
    # Since the app is running, count down that initial stack count
    activity.decrementCounter()

    # Check for states with authentication
    $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
      # If we have authentication and we're trying to log in, no stahp...
      if auth.isAuthenticated && toState.name is 'admin/login'
        event.preventDefault()
        $state.go 'admin'

      # If we don't have authentication, go to the log in page
      else if not auth.isAuthenticated && toState.options && toState.options.secure
        event.preventDefault()
        auth.desiredState =
          state:  toState.name
          params: toParams
        $state.go 'admin/login'

    # Reset the page title between states
    $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      title = if toState.options && toState.options.title
        toState.options.title
      else
        null

      page.setTitle title
]
