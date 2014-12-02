(function() {
    // Supports IE9+ and all other.
    if (!document.addEventListener) {
        return;
    }

    var scrollTo = function(element, to, duration) {
        if (duration < 0) {
            return;
        }
        var difference = to - element.scrollTop;
        var perTick = difference / duration * 10;

        setTimeout(function() {
            element.scrollTop = element.scrollTop + perTick;
            if (element.scrollTop === to) return;
            scrollTo(element, to, duration - 10);
        }, 10);
    };

    var scrollOutputWindowToBottom = function() {
        var outputWindow = document.getElementById('js-output');
        scrollTo(outputWindow, outputWindow.scrollHeight - outputWindow.offsetHeight, 100);
    };

    var initializeHandlers = function() {
        var actionButton = document.getElementById('js-scroll-output');

        if (actionButton) {
            actionButton.style.visibility = 'visible';
            actionButton.addEventListener('click', scrollOutputWindowToBottom);
        }
    };

    document.addEventListener('DOMContentLoaded', initializeHandlers, false);
})();
