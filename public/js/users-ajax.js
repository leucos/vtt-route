$(document).ready(function(){
  $('#search').focusout(function() {
    $('#propositions').hide();
  });  
  $('#search').keyup(function() {
    console.log("got key up");
    var pattern = $('#search').val();
    if (pattern.length > 2 ) {
      $.ajax({
        url: "/backoffice/users/" + $("#search").val() + ".json",
        success: function(result){
          $('#propositions').show(function() {
            var buf = "";
            for (var i=0; i<result.length; i++) {
              console.log(result[i]["values"]["name"]);
              buf += "<p><a href=#>" + result[i]["values"]["surname"] + " " + result[i]["values"]["name"] + "</a></p>";
            }
            $(this).html(buf);
          });
        }
      });
    }
  });

  $("span.toggle-button").hover( function () {
    $(this).css('cursor','pointer');
  });

  $('span.toggle-button').click(function() {
    var target = $(this);
    var parts = $(this).attr("id").split("-");
    var method = parts[0];
    var id = parts[1];

    $.ajax({
      url: "/backoffice/toggle_document/" + method + "/" + id + ".json",
      success: function(result) {
        if (result == true) {
          target.fadeOut('fast', function() {
            target.removeClass("badge-important").addClass("badge-success").fadeIn('fast');
            target.html('<i class="icon-ok icon-white"></i> Reçu');
          });
        } else {
          target.fadeOut('fast', function() {
            target.removeClass("badge-success").addClass("badge-important").fadeIn('fast');            
            target.html('<i class="icon-remove icon-white"></i> Manquant');
          });
        }
      }
    });
  });  

});


