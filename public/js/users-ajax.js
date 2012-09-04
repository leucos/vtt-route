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
});


