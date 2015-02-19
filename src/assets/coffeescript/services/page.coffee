# Service for managing the page in general
angular.module('skinnyBlog').factory 'Page', [
  '$rootScope',
  ($rootScope) -> new class Page
    # Set's the title in the head tag
    setTitle: (title) -> $rootScope.title = title
]