

# INITIALIZATION
tabcat.ui.enableFastClick()
tabcat.ui.turnOffBounce()

$(->
  $squareDiv = $('div.square')
  tabcat.ui.fixAspectRatio($squareDiv, 1)
  tabcat.ui.linkEmToPercentOfHeight($squareDiv)

  $('#instructions').show()
)
