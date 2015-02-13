angular.module('skinnyBlog').factory 'AuthService', [
  '$http', '$cacheFactory', '$window', '$q', 'ApiService',
  ($http,   $cacheFactory,   $window,   $q,   api) -> new class AuthService
    constructor: ->
      window.auth = @
      @token = null
      @isAuthenticated = false
      @desiredState = false

    # The annoying sign-in process
    signIn: ->
      deferred = $q.defer()

      # The callback that will hopefully resolve everything
      $window.googleOauthCallback = (result) =>
        if result['status']['signed_in']
          @token = result.access_token

          # Validate the authentication
          api.hasValidAuthentication(@token).success =>
            @isAuthenticated = true
            deferred.resolve()
          .error ->
            deferred.reject 'You do not have permission to access this area'
        else
          deferred.reject 'Could not authenticate against Google OAuth'

      # Get the client ID before triggering anything
      api.getAuthInfo().success (data) ->
        $window.gapi.auth.signIn
          clientid:     data.clientId
          cookiepolicy: 'single_host_origin'
          callback:     'googleOauthCallback'
      .error ->
        deferred.reject 'Could not get OAuth client ID'

      return deferred.promise
]

