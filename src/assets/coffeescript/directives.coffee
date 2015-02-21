
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

# Helper function for the tag matching
filterTags = (query) -> (tag) -> tag.match(new RegExp(query, 'i'))

# Directive for tag authoring
app.directive 'bhTagInput', [
  '$q', '$timeout', 'ApiService', 'AuthService', 'ActivityService',
  ($q,   $timeout,   api,          auth,          activity) ->
    restrict: 'A'
    scope:
      addTag: '&'
      removeTag: '&'
      tags: '='
    link: ($scope, element, attrs) ->
      require ['jquery-ui'], ->
        require ['tag-it'], ->
          $element = $(element)
          tags = null
          tagMap = {}
          populatingTags = false

          # Helper for grabbing a tag object from the master list
          getTagFromLabel = (tag) ->
            if tagMap[tag] isnt undefined
              id:   tagMap[tag]
              name: tag
            else
              name: tag

          # Helper for refreshing the tag list
          refreshTags = ->
            populatingTags = true
            $element.tagit 'removeAll'
            $element.tagit('createTag', tag.name) for tag in $scope.tags
            populatingTags = false

          # Grab all of our tags
          tagDeferred = $q.defer()
          promise = api.getTags auth.token
          activity.addPromise promise

          promise.success (data) ->
            # Set up the tag mapping
            for tag in data.tags
              tagMap[tag.name] = tag.id

            # Set up the tag array for tag-it
            tags = (tag.name for tag in data.tags)

            # Update our lists
            if $scope.tags
              refreshTags()

            # Notify the deferred that we're done
            tagDeferred.resolve()
          .error ->
            tagDeferred.rejct()

          # Set up the tag-it element
          $element.tagit
            allowSpaces:        true
            removeConfirmation: true
            autocomplete:
              delay: 0
              minLength: 1
              source: (request, response) ->
                # Only fetch the tags the first time
                if not tags
                  # Wait for the tags to finish if we need to
                  tagDeferred.success (data) ->
                    response tags.filter(filterTags request.term)
                  .error ->
                    response []
                else
                  response tags.filter(filterTags request.term)

            # Ensure that our tag is all lower case and kosher
            beforeTagAdded: (event, ui) ->
              span = ui.tag.find('span.tagit-label')
              text = span.text().toLowerCase().replace /[^0-9a-z ]+/ig, ''
              span.text text

            # Tells the controller that we've added a tag
            afterTagAdded: (event, ui) ->
              if not populatingTags
                $timeout ->
                  $scope.tags.push getTagFromLabel(ui.tagLabel)

            # Inform the controller that we've removed a tag
            afterTagRemoved: (event, ui) ->
              if not populatingTags
                $timeout ->
                  for tag, index in $scope.tags
                    if tag.name is ui.tagLabel
                      $scope.tags.splice index, 1

          # Watch for model changes
          $scope.$watch 'tags', (newVal, oldVal) ->
            if newVal != oldVal
              refreshTags()
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

# Pagination
app.directive 'bhPagination', ->
  restrict: 'E'
  replace: true
  template: """
<nav>
    <ul class="pager">
        <li class="previous">
            <a ng-href="{{ previousHref }}" ng-show="!previousDisabled" class="pure-button">
                <span aria-hidden="true">&larr;</span> Older
            </a>
        </li>
        <li class="next">
            <a ng-href="{{ nextHref }}" ng-show="!nextDisabled" class="pure-button">
                Newer <span aria-hidden="true">&rarr;</span>
            </a>
        </li>
    </ul>
</nav>
"""
  scope:
    previousDisabled: '='
    previousHref: '='
    nextDisabled: '='
    nextHref: '='
