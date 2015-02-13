
app = angular.module('skinnyBlog', ['ui.router']).config [
  '$stateProvider', '$urlRouterProvider', '$locationProvider', '$provide',
  ($stateProvider,   $urlRouterProvider,   $locationProvider,   $provide) ->
    # Turn on HTML5 url mode
    $locationProvider.html5Mode true

    # Set up our states/routes
    $stateProvider
      # List of articles
      .state 'articles',
        url:         '^/'
        templateUrl: 'partials/articles.html'
        controller:  'ArticlesController as articles'

      # Lists articles with the given tag
      .state 'tag',
        url:         '^/tag/:tag'
        templateUrl: 'partials/articles.html'
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

      # Admin - Edit an article
      .state 'admin/article',
        url:         '^/admin/articles/{id:[0-9]+}'
        templateUrl: 'partials/admin/article.html'
        controller:  'AdminArticleController as admin'
        options:
          secure: true

      # Admin - Create an article
      .state 'admin/article/new',
        url:         '^/admin/articles/new'
        templateUrl: 'partials/admin/article.html'
        controller:  'AdminArticleController as admin'
        options:
          secure: true

      # Admin - Create an article
      .state 'admin/login',
        url:         '^/admin/login'
        templateUrl: 'partials/admin/login.html'
        controller:  'AdminLoginController as login'

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
  '$rootScope', '$state', 'ActivityService', 'AuthService',
  ($rootScope,   $state,   activity,          auth) ->
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
        console.log auth.desiredState
        $state.go 'admin/login'
]


# Directive for showing an article
app.directive 'bhArticle', ->
  restrict:    'E'
  templateUrl: 'partials/article.html'
  scope:
    article: '=bhModel'


# Directive for markdown processing
app.directive 'bhMarkdown', ->
  restrict: 'A'
  scope:
    markdown: "&bhMarkdown"
  link: (scope, element, attrs) ->
    require ['marked', 'highlight'], (marked, hljs) ->
      # Set up syntax highlighting
      marked.setOptions
        langPrefix: 'hljs '
        highlight: (code) ->
          hljs.highlightAuto(code).value

      # Set up our watcher
      watcher = -> element.html marked(scope.markdown()) if scope.markdown()
      watcher()
      scope.$watch scope.markdown, watcher



# Directive for markdown processing
app.directive 'bhPickadate', ->
  restrict: 'A'
  scope:
    date: '=bhPickadate'
    updateFn: '&bhPickadateChange'
  link: (scope, element, attrs) ->
    require ['picker', 'picker.date'], ->
      $element = $(element)
      $element.pickadate
        format: 'd mmmm yyyy'
        onSet: (context) ->
          date = context.select
          # If a Date object is being set, it came from us
          if not (date instanceof Date)
            scope.date.setTime date

      picker = $element.pickadate 'picker'

      watchFn = (date) -> picker.set('select', date) if date
      watchFn scope.date
      scope.$watch 'date', watchFn


# Directive for show an editor
app.directive 'bhEditor', ->
  restrict: 'A'
  scope:
    theme:    '@bhEditorTheme'
    language: '@bhEditorLanguage'
    update:   '&bhEditorUpdate'
    model:    '=bhEditorModel'
  link: (scope, element, attrs) ->
    require ['ace'], ->
      theme = if scope.theme then scope.theme else 'monokai'
      language = if scope.language then scope.language else 'markdown'

      editor = ace.edit element[0]
      editor.setTheme 'ace/theme/' + theme
      editor.getSession().setMode 'ace/mode/' + language
      editor.getSession().setUseSoftTabs true

      # Set the value on the first run-through
      editor.setValue(scope.model) if scope.model

      # Listen for changes
      scope.$watch 'model', ->
        # Only update the first time to prevent stupid crap from happening
        if not editor.getValue() && scope.model
          editor.setValue scope.model

      # Push changes back
      editor.getSession().on 'change', -> scope.update() editor.getValue()
