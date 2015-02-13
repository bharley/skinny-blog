angular.module('skinnyBlog').controller 'AlertController', [
  '$scope', '$timeout', 'AlertService',
  ($scope,   $timeout, alert) -> new class AlertController
    constructor: ->
      @alerts = []

      # Listen for new alerts
      $scope.$on 'newAlert', (event, alert) =>
        console.log 'Caught a new alert'
        $timeout =>
          console.log 'Pewshing it'
          console.log alert
          @alerts.push alert

    # Closes an alert
    close: (index) ->
      @alerts.splice index, 1
]