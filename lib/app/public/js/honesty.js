'use strict';

(function($) {
  $.each(['jarvis', 'frick', 'tim', 'tp'], function(index, codebase) {
    $('#' + codebase + '_branch').autocomplete({
      source: '/pancakes/branches/' + codebase + '.json',
      delay: 300,
      minLength: 1
    });
  });
})(jQuery);
