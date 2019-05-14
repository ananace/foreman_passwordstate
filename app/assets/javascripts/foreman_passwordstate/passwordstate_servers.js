$(function() {
  passwordstate_server_form_binds();
});

function show_authorization_form(self) {
  let select = $(self);
  $('fieldset.authorization_form').hide();
  $('#passwordstate_' + select.val()).show();
}

function testConnection(item) {
  $('.tab-error').removeClass('tab-error');
  // $('#test_connection_indicator').show();
  $.ajax({
    type: 'post',
    url: $(item).attr('data-url'),
    data: `${$('form').serialize()}`,
    success(result) {
      $('#test_connection_button').attr('class', 'btn btn-success');
    },
    error({ statusText }) {
      $('#test_connection_button').attr('class', 'btn btn-warning');
    },
    complete(result) {
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
