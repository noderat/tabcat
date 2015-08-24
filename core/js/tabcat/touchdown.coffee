###
Copyright (c) 2013-2014, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

#Different devices have different events that they can respond to.
#Some of the devices support touchstart or mousedown only,
#And some support both, in which case they will respond to both events
#When only one is necessary.  This fix is an extension function to jQuery
#To be used in place of the jQuery "on" function.  It was inspired by many
#posts on the topic on the web, one of which was a stack overflow response:
# http://stackoverflow.com/questions/13655919/how-to-bind-both-mousedown-
# and-touchstart-but-not-respond-to-both-android-jqu
# Note: the above URL is broken into two lines to avoid the 80-characcter line
# limit of CoffeeLint

(($) ->
  $.fn.touchdown = (onclick) ->
    @bind 'touchstart', (event) ->
      onclick.call this, event
      event.stopPropagation()
      event.preventDefault()
      return
    @bind 'mousedown', (event) ->
      onclick.call this, event
      return
    this

  return
)(jQuery)