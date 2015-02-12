
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

      .state 'admin',
        url:         '^/admin'
        templateUrl: 'partials/admin/dashboard.html'
        controller:  'AdminDashboardController as dashboard'

      .state 'admin/article',
        url:         '^/admin/articles/{id:[0-9]+}'
        templateUrl: 'partials/admin/article.html'
        controller:  'AdminArticleController as article'

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
  'ActivityService',
  (activity) ->
    # Since the app is running, count down that initial stack count
    activity.decrementCounter()
]

# Directive for markdown processing
app.directive 'bhMarkdown', ->
  restrict: 'A'
  scope:
    markdown: "&bhMarkdown"
  link: (scope, element, attrs) ->
    scope.$watch scope.markdown, ->
      element.html marked(scope.markdown()) if scope.markdown()


# Directive for markdown processing
app.directive 'bhPickadate', ->
  restrict: 'A'
  scope:
    date: '=bhPickadate'
    updateFn: '&bhPickadateChange'
  link: (scope, element, attrs) ->
    $element = $(element)
    $element.pickadate
      format: 'd mmmm yyyy'
      onSet: (context) ->
        date = context.select
        # If a Date object is being set, it came from us
        if not (date instanceof Date)
          scope.date.setTime date
          console.log scope.updateFn()

    picker = $element.pickadate 'picker'

    scope.$watch 'date', (date) -> picker.set('select', date) if date


# Directive for show an editor
app.directive 'bhEditor', ->
  restrict: 'A'
  scope:
    theme:    '@bhEditorTheme'
    language: '@bhEditorLanguage'
    update:   '&bhEditorUpdate'
    model:    '=bhEditorModel'
  link: (scope, element, attrs) ->
    theme = if scope.theme then scope.theme else 'monokai'
    language = if scope.language then scope.language else 'markdown'

    editor = ace.edit element[0]
    editor.setTheme 'ace/theme/' + theme
    editor.getSession().setMode 'ace/mode/' + language
    editor.getSession().setUseSoftTabs true

    # Listen for changes
    scope.$watch 'model', ->
      # Only update the first time to prevent stupid crap from happening
      if not editor.getValue() && !! scope.model
        editor.setValue(scope.model)

    # Push changes back
    editor.getSession().on 'change', -> scope.update() editor.getValue()
