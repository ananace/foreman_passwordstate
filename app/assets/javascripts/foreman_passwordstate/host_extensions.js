var PASSWORD_LIST_ID=""
$(function() {
  if ($('#host_passwordstate_facet_attributes_password_list_id').length != 0) {
    PASSWORD_LIST_ID = '#host_passwordstate_facet_attributes_password_list_id'
  } else {
    PASSWORD_LIST_ID = '#hostgroup_passwordstate_facet_attributes_password_list_id'
  }

  update_passwordstate_list($(PASSWORD_LIST_ID));

  $(document.body).on('ContentLoad', function() {
    update_passwordstate_list($(PASSWORD_LIST_ID));
  });
});

function update_passwordstate_server(element) {
  var url = $(element).attr('data-url');
  var type = $(element).attr('data-type');
  var attrs = {};
  attrs[type] = attribute_hash(['passwordstate_server_id']);
  $('#root_password').show();
  tfm.tools.showSpinner();
  $.ajax({
    data: attrs,
    type:'post',
    url: url,
    complete: function(){
      reloadOnAjaxComplete(element);
    },
    success: function(response) {
      data = $(response);
      $('#passwordstate_list_select').html(data.html());
      update_passwordstate_list($(PASSWORD_LIST_ID));
    }
  });
}

function update_passwordstate_list(element) {
  var element = $(element);

  if (element[0].options.length == 0) {
    $('#passwordstate_list_select').hide();
  } else {
    $('#passwordstate_list_select').show();
  }

  if (element.val()) {
    $('#root_password').hide();
  } else {
    $('#root_password').show();
  }
}
