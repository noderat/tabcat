// requires: jquery

LLT = function() {
    var LLT = {}

    LLT.debugMode = false;

    LLT.startTimestamp = null;
    LLT.endTimestamp = null;

    LLT.fontSizeAsPercentOfHeight = 2;
    LLT.aspectRatio = 4/3; // pretend we're on an iPad

    // as a percentage of container
    var shortLineMinLength = 40;
    var shortLineMaxLength = 50;
    // as a percentage of the short line's length
    var lineOffsetAtCenter = 50;

    var minIntensity = 1;
    var maxIntensity = 50;
    var intensityChangeOnHit = -1;
    var intensityChangeOnMiss = 3;
    var startIntensity = 15;
    var practiceStartIntensity = 40;
    LLT.intensity = practiceStartIntensity;
    // used to track reversals. not maintained in practice mode
    LLT.lastIntensityChange = 0;

    var maxReversals = 20;
    LLT.intensitiesAtReversal = [];
    LLT.numTrials = 0;

    var practiceMaxStreakLength = 4;
    var practiceCaptionMaxStreakLength = 2;
    LLT.practiceStreakLength = 0;

    var numLayouts = 2;

    var inPracticeMode = function() {
	return LLT.practiceStreakLength < practiceMaxStreakLength;
    };

    var shouldShowPracticeCaption = function() {
	return LLT.practiceStreakLength < practiceCaptionMaxStreakLength;
    };

    var taskIsDone = function() {
	return LLT.intensitiesAtReversal.length >= maxReversals;
    }

    var randomUniform = function(a, b) {
	return a + Math.random() * (b - a);
    };

    var coinFlip = function(a, b) {
	return Math.random() < 0.5;
    }

    var clamp = function(min, x, max) {
	return Math.min(max, Math.max(min, x));
    }

    var recordResult = function(correct) {
	if (LLT.startTimestamp === null) {
	    LLT.startTimestamp = $.now();
	}

	var change = correct ? intensityChangeOnHit : intensityChangeOnMiss;

	var lastIntensity = LLT.intensity;
	LLT.intensity = clamp(
	    minIntensity, lastIntensity + change, maxIntensity);
	var intensityChange = LLT.intensity - lastIntensity;

	if (inPracticeMode()) {
	    if (correct) {
		LLT.practiceStreakLength += 1;
		if (!inPracticeMode()) {
		    // if we've left practice mode, start the real test
		    LLT.intensity = startIntensity;
		    LLT.lastIntensityChange = 0;
		}
	    } else {
		LLT.practiceStreakLength = 0;
	    }
	} else {
	    // count no change (hitting the floor/ceiling) as a reversal
	    var wasReversal = (intensityChange * LLT.lastIntensityChange < 0 ||
			       intensityChange === 0)
	    if (wasReversal) {
		LLT.intensitiesAtReversal.push(lastIntensity);
	    }
	    LLT.lastIntensityChange = intensityChange;
	}

	LLT.numTrials += 1;
    };

    LLT.getNextTrial = function() {
	var shortLineLength = randomUniform(
	    shortLineMinLength, shortLineMaxLength);

	var longLineLength = shortLineLength * (1 + LLT.intensity / 100)

	if (coinFlip()) {
	    var topLineLength = shortLineLength;
	    var bottomLineLength = longLineLength;
	} else {
	    var topLineLength = longLineLength;
	    var bottomLineLength = shortLineLength;
	}

	var centerOffset = shortLineLength * lineOffsetAtCenter / 100;

	// make sure both lines are the same distance from the edge
	// of the screen
	var totalWidth = (topLineLength / 2 + bottomLineLength / 2 +
			  centerOffset);
	var margin = (100 - totalWidth) / 2;

	// push one line to the right, and one to the left
	if (coinFlip()) {
	    var topLineLeft = margin;
	    var bottomLineLeft = 100 - margin - bottomLineLength;
	} else  {
	    var topLineLeft = 100 - margin - topLineLength;
	    var bottomLineLeft = margin;
	}

	return {
	    topLine: {
		css: {left: topLineLeft + '%',
		      width: topLineLength + '%'},
		isLonger: (topLineLength >= bottomLineLength)
	    },
	    bottomLine: {
		css: {left: bottomLineLeft + '%',
		      width: bottomLineLength + '%'},
		isLonger: (bottomLineLength >= topLineLength)
	    },
	    shortLineLength: shortLineLength,
	    intensity: LLT.intensity
	};
    };

    LLT.showNextTrial = function(e) {
	if (e && e.data) {
	    recordResult(e.data.isLonger);
	}

	if (taskIsDone()) {
	    LLT.finishTask();
	} else {
	    var nextTrialDiv = LLT.nextTrialDiv();
	    $('#task-main').empty();
	    $('#task-main').append(nextTrialDiv);
	    LLT.fixAspectRatio(nextTrialDiv);
	    LLT.fixFontSize(nextTrialDiv);
	    $(nextTrialDiv).fadeIn({duration: 200});
	}
    };

    LLT.finishTask = function(e) {
	LLT.endTimestamp = $.now();

	$('#scoring .score-list').text(LLT.intensitiesAtReversal.join(', '))
	var elapsedSecs = (LLT.endTimestamp - LLT.startTimestamp) / 1000;
	// we start timing after the first click, so leave out the first
	// trial in timing info
	$('#scoring .elapsed-time').text(
	    elapsedSecs.toFixed(1) + 's / ' + (LLT.numTrials - 1) + ' = ' +
	    (elapsedSecs / (LLT.numTrials - 1)).toFixed(1) + 's');

	$('#task').hide();
	$('#done').fadeIn({duration: 200});

	var showScoringButton = $('#show-scoring');
	showScoringButton.bind('click', LLT.showScoring);
	showScoringButton.removeAttr('disabled');
    };

    LLT.showScoring = function(e) {
	$('#done').hide();
	$('#scoring').fadeIn({duration: 200});
    };

    LLT.nextTrialDiv = function() {
	// get line offsets and widths for next trial
	var trial = LLT.getNextTrial();

	// construct divs for these lines
	var topLineDiv = $('<div></div>', {'class': 'line top-line'})
	topLineDiv.css(trial.topLine.css);
	topLineDiv.bind('click', trial.topLine, LLT.showNextTrial);

	var bottomLineDiv = $('<div></div>', {'class': 'line bottom-line'})
	bottomLineDiv.css(trial.bottomLine.css);
	bottomLineDiv.bind('click', trial.bottomLine, LLT.showNextTrial);

	if (LLT.debugMode) {
	    var shortLineDiv = (trial.topLine.isLonger ?
				bottomLineDiv : topLineDiv);
	    var longLineDiv = (trial.topLine.isLonger ?
			       topLineDiv: bottomLineDiv);
	    shortLineDiv.text(trial.shortLineLength.toFixed(2) +
			      '% of screen width');
	    longLineDiv.text(trial.intensity + '% longer than short line');
	}

	// put them in an offscreen div
	var containerDiv = $(
	    '<div></div>', {
		'class': 'layout-' + LLT.numTrials % numLayouts});
	$(containerDiv).hide()
	containerDiv.append(topLineDiv, bottomLineDiv);

	// show practice caption, if required
	if (shouldShowPracticeCaption()) {
	    var practiceCaptionDiv = $('<div></div>',
				       {'class': 'practice-caption'});
	    practiceCaptionDiv.html('Tap the longer line<br>' +
				    ' quickly and accurately.');
	    containerDiv.append(practiceCaptionDiv);
	}

	return containerDiv;
    };

    LLT.fixFontSize = function(element, percentOfHeight) {
	element = $(element);
	percentOfHeight = percentOfHeight || LLT.fontSizeAsPercentOfHeight;

	var fixElement = function(e) {
	    var sizeInPx = element.height() * percentOfHeight / 100;
	    element.css({'font-size': sizeInPx + 'px'});
	}

	fixElement(element);

	$(window).resize(fixElement);
    }

    LLT.fixAspectRatio = function(element, ratio) {
	element = $(element);
	ratio = ratio || LLT.aspectRatio;

	var fixElement = function(e) {
	    var parent = $(element.parent());
	    var parentWidth = parent.width();
	    var parentHeight = parent.height();
	    var parentRatio = parentWidth / parentHeight;

	    if (parentRatio > ratio) {
		// parent is too wide, need gap on left and right
		var gap = 100 * (parentRatio - ratio) / parentRatio / 2;
		element.css({
		    position: 'absolute',
		    left: gap + '%',
		    right: 100 - gap + '%',
		    width: 100 - 2 * gap + '%',
		    top: '0%',
		    bottom: '100%',
		    height: '100%'
		});
	    } else {
		// parent is too narrow, need gap on top and bottom
		var gap = (100 * (1 / parentRatio - 1 / ratio) *
			   parentRatio / 2);
		element.css({
		    position: 'absolute',
		    left: '0%',
		    right: '100%',
		    width: '100%',
		    top: gap + '%',
		    bottom: 100 - gap + '%',
		    height: 100 - 2 * gap + '%'
		});
	    }
	};

	fixElement(element);

	$(window).resize(fixElement);
    }

    return LLT;
}();
