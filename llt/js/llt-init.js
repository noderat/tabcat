// turn off elastic scrolling (scrolling up/down past the end of the document)
$(document).bind(
    'touchmove',
    function(e) {
	e.preventDefault();
    }
);

LLT.fixFontSize($(document.body));

$(function() {
    FastClick.attach(document.body);
});

LLT.showNextTrial();
