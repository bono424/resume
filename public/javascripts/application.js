// index
$("#register").submit(function() {
  console.log($(this).serializeArray());
  var inputs = $('#register').serializeArray();
  $.each(inputs, function(i, input) {
    if (input.value == "") { 
      $('input[name='+input.name+']').parents('.control-group').addClass('warning');
      $('input[name='+input.name+']').siblings('.help-inline').show();
      return false;
    } 
  });
});

// profiles

$('.edit-icon').click(function() {
  $(this).parents('.row').children('.edit').toggle();
  $(this).parents('.row').children('.info').toggle();
});

$('.add-icon').click(function() {
  $(this).parents('.row').children('.add').toggle();
});

// input validations

function isNumber(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

$('form').submit(function() {
  console.log($(this).serializeArray());
  var inputs = $(this).serializeArray();
  $.each(inputs, function(i, input) {
    if (input.name == "class") { 
      isNumber(input.value) && input.value.length == 4 ? alert("valid") : alert("invalid");
    } 
    if (input.name == "gpa") { 
      isNumber(input.value) ? alert("valid") : alert("invalid");
    } 
  });
  return true;
});
