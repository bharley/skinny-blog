angular.module('skinnyBlog').controller 'AdminLoginController', [
  '$state', 'AuthService', 'ActivityService', 'AlertService',
  ($state,   auth,          activity,          alert) -> new class AdminLoginController
    constructor: ->
      @signingIn = false

    attempt: ->
      @signingIn = true
      promise = auth.signIn()
      activity.addPromise promise

      promise.success =>
        @signingIn = false

        if auth.desiredState
          $state.go auth.desiredState.state, auth.desiredState.params
        else
          $state.go 'admin'
      .error (message) =>
        @signingIn = false
        alert.add "Error: #{message}"
]