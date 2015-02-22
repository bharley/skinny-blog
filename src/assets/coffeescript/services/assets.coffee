angular.module('skinnyBlog').factory 'AssetService', [
  '$window',
  ($window) -> new class AssetService
    constructor: ->
      @assetMap =
        'jquery-ui':      '//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.11.2/jquery-ui.min.css'
        'pure-forms':     '//cdnjs.cloudflare.com/ajax/libs/pure/0.5.0/forms-min.css'
        'pickadate':      '//cdnjs.cloudflare.com/ajax/libs/pickadate.js/3.5.3/compressed/themes/default.css'
        'pickadate-date': '//cdnjs.cloudflare.com/ajax/libs/pickadate.js/3.5.3/compressed/themes/default.date.css'
      @loadedAssets = []

    requireMany: (assets) ->
      @require(asset) for asset in assets

    require: (asset) ->
      if not @assetLoaded asset
        path = if @assetMap[asset]
          @assetMap[asset]
        else
          asset

        @loadStylesheet path
        @loadedAssets.push asset

    assetLoaded: (asset) -> @loadedAssets.indexOf(asset) isnt -1

    loadStylesheet: (path) ->
      link = $window.document.createElement 'link'
      link.rel  = 'stylesheet';
      link.type = 'text/css';
      link.href = path;
      $window.document.getElementsByTagName('head')[0].appendChild link
]