// this identifies your website in the createToken call below
Stripe.setPublishableKey('pk_test_4YpFm6fKhAYSBCft70ZMjaxX');

function stripeResponseHandler(status, response) {
    if (response.error) {
        // re-enable the submit button
        $('.submit-button').removeAttr("disabled");
        // show the errors on the form
        $(".alert-error").html(response.error.message);
        alert(response.error.message);
    } else {
        var form$ = $("#employer_subscribe");
        // token contains id, last4, and card type
        var token = response['id'];
        // insert the token into the form so it gets submitted to the server
        form$.append("<input type='hidden' name='token' value='" + token + "' />");
        // and submit
        form$.get(0).submit();
    }
}

$(document).ready(function() {
    $("#employer_subscribe").submit(function(event) {
        // disable the submit button to prevent repeated clicks
        $('.submit-button').attr("disabled", "disabled");
		// split expiry date
		var expiry_date = $('.card-expiry').val();
		expiry_date = expiry_date.split('/');
		var expiry_month = expiry_date[0];
		var expiry_year = expiry_date[1];

        // createToken returns immediately - the supplied callback submits the form if there are no errors
        Stripe.createToken({
            number: $('.card-number').val(),
            cvc: $('.card-cvc').val(),
            exp_month: expiry_month,
            exp_year: expiry_year
        }, 0, stripeResponseHandler);
        return false; // submit from callback
    });
});
