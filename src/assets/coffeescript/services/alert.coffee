angular.module('skinnyBlog').factory 'AlertService', [
  '$rootScope',
  ($rootScope) -> new class AlertService
    constructor: -> window.aleets = @

    # Broadcasts an alert at the root scope
    add: (message, type = 'danger') ->
      $rootScope.$broadcast 'newAlert',
        message: message
        type:    type
]