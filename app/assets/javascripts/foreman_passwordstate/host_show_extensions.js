function trigger_delayed_ajax(element) {
  $(element).each(function() {
    var url = $(this).data('delayed-ajax-url');
    $(this).attr('data-ajax-url', url);
    onContentLoad();
  });
}
