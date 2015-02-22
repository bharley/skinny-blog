
# Controls the activity indicator
angular.module('skinnyBlog').factory 'ActivityService', [
  '$window'
  ($window)-> new class Activity
    constructor: ->
      @element = angular.element $window.document.getElementById('activity-spinner')
      @class = 'off'

      # The number of activities on the stack
      @counter = 1

    # Counts down the number of activities on the stack and hides the spinner if necessary
    decrementCounter: ->
      @counter--
      @counter = 0 if @counter < 0
      @element.addClass(@class) if @counter is 0

    # Counts up the number of activities on the stack and displays the spinner if necessary
    incrementCounter: ->
      @counter++
      @element.removeClass(@class) if @counter > 0

    # Adds a promise to the stack
    addPromise: (promise) ->
      @incrementCounter()
      decrement = => @decrementCounter()
      promise.then decrement, decrement
]