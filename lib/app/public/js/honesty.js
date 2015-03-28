'use strict';

(function($) {

  $('.start-tracking-btn').click(function() {
    $('.start-tracking-btn').addClass('disabled');
    $('.start-tracking-btn').text('Wait for page reload...');
  });

  $.each(['jarvis', 'frick', 'tim'], function(index, codebase) {
    $('#' + codebase + '_branch').autocomplete({
      source: '/pancakes/branches/' + codebase + '.json',
     minLength: 1
    });
  });

})(jQuery);
