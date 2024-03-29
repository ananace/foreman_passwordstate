$(function() {
  passwordstate_server_form_binds();
});

function show_authorization_form(self) {
  select = $(self);
  $('fieldset.authorization_form').hide();
  $('#passwordstate_' + select.val()).show();
}

function testConnection(item) {
  $('.tab-error').removeClass('tab-error');
  // $('#test_connection_indicator').show();
  $.ajax({
    type: 'post',
    url: $(item).attr('data-url'),
    data: $('form').serialize().toString(),
    success: function() {
      $('#test_connection_button').attr('class', 'btn btn-success').attr('title', '');
    },
    error: function(result) {
      $('#test_connection_button').attr('class', 'btn btn-warning').attr('title', result.toString());
    },
    complete: function() {
      // $('#test_connection_indicator').hide();
    },
  });
}

function passwordstate_server_form_binds() {
  $('select#passwordstate_server_api_type').on('click', function () {
      show_authorization_form(this);
  });
  show_authorization_form('select#passwordstate_server_api_type');
}
