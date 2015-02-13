angular.module('skinnyBlog').factory 'AuthService', [
  '$http', '$cacheFactory', '$window', '$q', '$cookieStore', 'ApiService',
  ($http,   $cacheFactory,   $window,   $q,   $cookieStore,   api) -> new class AuthService
    @tokenKey = 'oauthToken'

    constructor: ->
      @token = @getStoredToken()
      @isAuthenticated = !!@token
      @desiredState = false

    # Pulls a stored token out of cookieness if it's there and not expired
    getStoredToken: ->
      data = $cookieStore.get AuthService.tokenKey

      if data && (new Date(data.expiration)).getTime() > (new Date).getTime()
        data.token
      else
        null

    # Stores an OAuth token in cookieness
    storeToken: (token, expirationDate) ->
      $cookieStore.put AuthService.tokenKey,
        token:      token
        expiration: expirationDate

    # The annoying sign-in process
    signIn: ->
      deferred = $q.defer()

      # The callback that will hopefully resolve everything
      $window.googleOauthCallback = (result) =>
        if result['status']['signed_in']
          @token = result.access_token
          expires = new Date(parseInt(result.expires_at) * 1000)

          # Validate the authentication
          api.hasValidAuthentication(@token).success =>
            @isAuthenticated = true
            @storeToken @token, expires
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

