// index

$(window).load(function() {
  var theWindow        = $(window),
      $bg              = $("#index #bg"),
      aspectRatio      = $bg.width() / $bg.height();
                       
  function resizeBg() {
    if ( (theWindow.width() / theWindow.height()) < aspectRatio ) {
      $bg.removeClass().addClass('bgheight');
    } else {
      $bg.removeClass().addClass('bgwidth');
    } 
  } 
  theWindow.resize(resizeBg).trigger("resize");
});

$("#register form").submit(function() {
  var inputs = $(this).serializeArray();
  var fail = false;
  $.each(inputs, function(i, input) {
    if (input.value == "") { 
      $('input[name='+input.name+']').parents('.control-group').addClass('error');
      $('input[name='+input.name+']').siblings('.help-block').show(200);
      fail = true
    } 
    else {
      $('input[name='+input.name+']').parents('.control-group').removeClass('error');
      $('input[name='+input.name+']').siblings('.help-block').hide(200);
      fail = fail || false;
    }
  });
  if (fail) { return false };
});

// profiles

$('.edit-icon').click(function() {
  $(this).parents('.row').children('.edit').toggle();
  $(this).parents('.row').children('.info').toggle();
});

$('.add-icon').click(function() {
  $(this).parents('.row').children('.add').slideToggle();
  $(this).toggleClass('add-cancel');
});

// input validations

function isNumber(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

$('form').submit(function() {
  var inputs = $(this).serializeArray();
  var fail = false;
  $.each(inputs, function(i, input) {
    if (input.name == "class" && input.value != "") { 
      if (!isNumber(input.value) || input.value.length != 4) {
        $('input[name='+input.name+']').parents('.control-group').addClass('warning');
        $('input[name='+input.name+']').siblings('.help-inline').removeClass('hide');
        fail = true;
      }
    } 
    if (input.name == "gpa" && input.value != "") { 
      if (!isNumber(input.value)) {
        $('input[name='+input.name+']').parents('.control-group').addClass('warning');
        $('input[name='+input.name+']').siblings('.help-inline').removeClass('hide');
        fail = true;
      }
    } 
  });
  if (fail) { return false; }
});

// file upload

$('.btn-upload').click(function() {
  $(this).siblings('.file-upload').trigger('click');
});

$('.file-upload').change(function() {
  $(this).siblings('.btn-upload').addClass('btn-inverse').html('<i class="icon-ok icon-white"></i> File selected');
  $(this).siblings('.btn-upload i').addClass('icon-white'); // and the icon...
});

// contact

$('#contact > form').submit(function() {
  $('#submit-contact').addClass('disabled').html('<i class="icon-spinner icon-spin">')
  $.post($(this).attr('action'), $(this).serialize(), function(data){
    $('.modal-body').html("<h1>Thanks!</h1><p>We'll get back to you as soon as possible.</p>");
    $('.modal-footer').html("<button class='btn btn-success disabled'>Sent!</button>");
  }, "text");
  return false;
});
