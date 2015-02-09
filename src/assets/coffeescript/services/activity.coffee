
# Controls the activity indicator
angular.module('skinnyBlog').factory 'ActivityService', -> new class Activity
  constructor: ->
    @element = $('#activity-spinner')

    # The number of activities on the stack
    @counter = 1

  # Counts down the number of activities on the stack and hides the spinner if necessary
  decrementCounter: ->
    @counter--
    @counter = 0 if @counter < 0
    @element.finish().fadeOut() if @counter is 0

  # Counts up the number of activities on the stack and displays the spinner if necessary
  incrementCounter: ->
    @counter++
    @element.finish().fadeIn() if @counter > 0

  # Adds a promise to the stack
  addPromise: (promise) ->
    @incrementCounter()
    decrement = => @decrementCounter()
    promise.then decrement, decrement
