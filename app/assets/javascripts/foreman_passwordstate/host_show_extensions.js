function trigger_delayed_ajax(element) {
  $(element).each(function() {
    var url = $(this).attr('data-delayed-ajax-url');
    if (url) {
      $(this).removeAttr('data-delayed-ajax-url');
      $(this).attr('data-ajax-url', url);
      onContentLoad();
    }
  });
}
