'use strict';

(function($) {

  $('.start-tracking-btn').click(function() {
    $('.start-tracking-btn').addClass('disabled');
    $('.start-tracking-btn').text('Wait for page reload...');
  });

})(jQuery);
