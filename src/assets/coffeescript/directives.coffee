
app = angular.module('skinnyBlog')

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



# Directive for showing a date picker
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


# Directive for showing an editor
app.directive 'bhEditor', [
  'AuthService', 'ActivityService', 'AlertService',
  (auth,          activity,          alert) ->
    restrict: 'A'
    scope:
      theme:    '@bhEditorTheme'
      language: '@bhEditorLanguage'
      update:   '&bhEditorUpdate'
      model:    '=bhEditorModel'
    link: (scope, element, attrs) ->
      require ['ace', 'dropzone'], ->
        # Optional settings
        theme = if scope.theme then scope.theme else 'monokai'
        language = if scope.language then scope.language else 'markdown'

        # Set up the editor
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

        # Sets up the drop zone
        placeholder = '![Uploading...]()'
        $(element).dropzone
          url: '/api/images'
          headers:
            'X-OAuth-Token': auth.token
          acceptedFiles: 'image/*'

          # Triggered on a file drop
          drop: ->
            editor.insert placeholder
            activity.incrementCounter()

          # Replaces the placeholder with the actual file
          success: (file, response) ->
            editor.find placeholder
            editor.replace "![#{file.name}](#{response.image})"

          # Removes the placeholder and throws up an error
          error: (file, error, xhr) ->
            editor.find placeholder
            editor.replace ''
            alert.add 'There was an error uploading the image.'

          # Removes the activity indicator
          complete: ->
            activity.decrementCounter()
]

# Alerts
app.directive 'bhAlerts', [
  '$timeout',
  ($timeout) ->
    restrict: 'E'
    template: """
<div class="alert" role="alert" ng-repeat="alert in alerts" ng-class="'alert-' + alert.type">
    <button type="button" class="close" aria-label="Close" ng-click="close($index)">
        <span aria-hidden="true">&times;</span>
    </button>
    {{ alert.message }}
</div>
"""
    scope: {}
    link: ($scope, element, attrs) ->
      $scope.alerts = []

      # Listen for new alerts
      $scope.$on 'newAlert', (event, alert) ->
        # Tell the digest process that we have an update
        $timeout ->
          $scope.alerts.push alert

      # Close alerts
      $scope.close = (index) -> $scope.alerts.splice index, 1
]