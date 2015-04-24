'use strict';

(function($) {
  $.each(['jarvis', 'frick', 'tim'], function(index, codebase) {
    $('#' + codebase + '_branch').autocomplete({
      source: '/pancakes/branches/' + codebase + '.json',
      delay: 500,
      minLength: 1
    });
  });
})(jQuery);
