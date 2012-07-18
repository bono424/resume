$(document).ready(function() {

	// Open external links in a new window
	hostname = window.location.hostname
	$("a[href^=http]")
	  .not("a[href*='" + hostname + "']")
	  .addClass('link external')
	  .attr('target', '_blank');
	
	// hide all pencil icons
	$(".icon-pencil").hide();
	// hide input for rows
	$(".editable").children().children("input").hide();
	// hide experience form
	$(".expinput").hide();
	$(".editable").parent().find(".button").hide();
	
	// show pencil icon on hover
	$(".editable").hover(
		function () { $(this).find(".icon-pencil").show(); }, 
		function () { $(this).find(".icon-pencil").hide(); }
	);	
	$(".expeditable").hover(
		function () { $(this).find(".icon-pencil").show(); }, 
		function () { $(this).find(".icon-pencil").hide(); }
	);
	
	// if editable row clicked, convert text to input box
	$(".editable").click(function() {
		$(this).children(".info").hide();
		$(this).children().children("input").show();
		$(this).parent("form").find(".button").show();
	});
	
	// if editable exp click, convert entry to inputs/textarea
	$(".expeditable").click(function() {
		$(this).parent().find(".expinput").show();
		$(this).hide();
	});
	
	$(".cancel").click(function() {
		$(this).parent().parent().hide();
		$(this).parent().parent().parent().find(".expeditable").show();
		
	});
});
