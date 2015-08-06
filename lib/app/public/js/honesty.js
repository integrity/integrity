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
    var $textArea = $('body').add('textarea').addClass('hidden-textarea');
    $textArea.val(text);
    $textArea.select();

    try {
      document.execCommand('copy');
    } catch (err) { }

    $textArea.remove();
  }

  $('.copy-branch-name').click(function(event){
    event.preventDefault();
    var branch_name = $(this).data('branch-name');
    copyTextToClipboard(branch_name);
  });
})(jQuery);
