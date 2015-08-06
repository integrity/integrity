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
    var textArea = document.createElement("textarea");
    textArea.style.position = 'fixed';
    textArea.style.top = 0;
    textArea.style.left = 0;
    textArea.style.width = '2em';
    textArea.style.height = '2em';
    textArea.style.padding = 0;
    textArea.style.border = 'none';
    textArea.style.outline = 'none';
    textArea.style.boxShadow = 'none';
    textArea.style.background = 'transparent';

    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.select();

    try {
      var successful = document.execCommand('copy');
      var msg = successful ? 'successful' : 'unsuccessful';
      console.log('Copying text command was ' + msg);
    } catch (err) {
      console.log('Oops, unable to copy');
    }

    document.body.removeChild(textArea);
  }

  $('.copy-branch-name').click(function(){
    var branch_name = $(this).data('branch-name');
    copyTextToClipboard(branch_name);
  });
})(jQuery);
