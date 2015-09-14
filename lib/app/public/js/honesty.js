'use strict';

(function($) {
  $.each(['jarvis', 'frick', 'tim', 'tp', 'banyan'], function(index, codebase) {
    $('#' + codebase + '_branch').autocomplete({
      source: '/pancakes/branches/' + codebase + '.json',
      delay: 300,
      minLength: 1
    });
  });

  $.each( $('.age-anchor') , function() {
    var maxAge = 86400 * 4;
    var $this = $(this);
    var myAge = $this.data("age");
    var green = Color.makeRGB(254,196,79);
    var red = Color.makeRGB(217,95,14);
    var index = myAge / maxAge;
    index  = index > 1 ? 1 : index;
    var myColor = Color.linearInterpolate(index, green, red);
    $this[0].firstChild.style.color = myColor.cssRGB();
  });

  function copyTextToClipboard(text) {
    var textArea = document.createElement('textarea');
    textArea.className = 'hidden-textarea';
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.select();

    try {
      document.execCommand('copy');
    } catch (err) { }

    document.body.removeChild(textArea);
  }

  $('.copy-branch-name').click(function(event){
    event.preventDefault();
    $(this).text('Copied!');
    setTimeout(function() { $('.copy-branch-name').text('Copy'); }, 500);
    var branch_name = $(this).data('branch-name');
    copyTextToClipboard(branch_name);
  });

  function hideNamesWithoutVisibleStories() {
    $('li.user').show();
    var user_stories = $('li.user').next();
    user_stories.each(function(){
      var stories = $(this).find('i');
      var hide_name = true;
      stories.each(function(){
        if($(this).is(':visible')) {
          hide_name = false;
          return false;
        }
      });

      if(hide_name) {
        $(this).prev().hide();
      }
    });
  }

  $('.state-view-toggle button').click(function(event) {
    event.preventDefault();
    $(this).blur();
    $(this).button('toggle');
    $('a .' + $(this).data('toggle')).toggle();
    hideNamesWithoutVisibleStories();
  });
})(jQuery);
