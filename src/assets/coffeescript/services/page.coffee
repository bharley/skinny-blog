# Service for managing the page in general
angular.module('skinnyBlog').factory 'Page', [
  '$rootScope', '$window', '$location',
  ($rootScope,   $window,   $location) -> new class Page
    # Set's the title in the head tag
    setTitle: (title) ->
      $rootScope.title = title
      $window.ga 'send', 'pageview',
        page: $location.url()

    # Sets the header image for an article or something else
    setHeaderImage: (url) -> $rootScope.headerImage = url

    # Cleans up the page for a state change
    reset: ->
      $rootScope.title = null
      $rootScope.headerImage = null
]