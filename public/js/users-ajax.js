$(document).ready(function(){
  $('#search').keyup(function(e) {
    console.log("got key up");
    if (e.keyCode == 27) { 
      $('#propositions').hide();
      return;
    }

    var pattern = $('#search').val();
    if (pattern.length > 2 ) {
      $.ajax({
        url: "/backoffice/users/" + $("#search").val() + ".json",
        success: function(result){
          if (result.length > 0) { 
            $('#propositions').show(function() {
              var buf = "";
              for (var i=0; i<result.length; i++) {
                console.log(result[i]["values"]["name"]);
                buf += "<p><a href=\"/backoffice/edit_user/" + result[i]["values"]["user_id"] + "\">" + result[i]["values"]["surname"] + " " + result[i]["values"]["name"] + "</a></p>";
              }
              $(this).html(buf);
            });
          }
        }
      });
    }
  });

  $("span.toggle-button,span.team-remove,span.team-add,span.plate-generate").hover( function () {
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
        if (result === true) {
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


  $('span.team-remove').click(function() {
    var target = $(this);
    var uid = target.attr("data-userid");
    var tid = target.attr("data-teamid");

    person = target.attr("data-username");
    team = target.text();

    console.log("tid : " + tid + " uid : " + uid);
    console.log($('#team-suppress-form').attr('data-baseaction'));

    $('#team-suppress-body').html("Voulez vous supprimer " + person + " de l'équipe <strong>" + team + "</strong> ?");
    $('#team-suppress-form').attr('action', $('#team-suppress-form').attr('data-baseaction') + "/" + tid + "/" + uid);

    $('#team-suppress-modal').modal('show');
  });

  $('span.team-add').click(function() {
    var target = $(this);
    var uid = target.attr("data-userid");

    $('#team-create-form').attr('action', $('#team-create-form').attr('data-baseaction') + "/" + uid);
    $('#team-add-form').attr('action', $('#team-add-form').attr('data-baseaction') + "/" + uid);

    console.log($('#team-add-form').attr('action'));
    $('#team-add-modal').modal('show');

  });

  $('button.plate-generate').click(function() {
    var target = $(this);
    var tid = target.attr("data-teamid");
    var input = $("#input-" + tid);
    console.log("click:" + tid);

    $.ajax({
      url: "/teams/get_plate_for/" + tid,
      success: function(result) {
        console.log(result);
        console.log(result['id']);

        if (result['status'] === true) {
          input.val(result['id']);
          input.fadeOut('slow', function() {
            input.removeClass("error").addClass("success").fadeIn('slow');
          });
        } else {
          input.fadeOut('slow', function() {
            input.removeClass("success").addClass("error").fadeIn('slow');
          });
        }
      }
    });
  });

  $('input.plate').change(function() {
    // ajax save in db if ok (may be just check if field has ok class)
    // reset field to initial value if save fails
    //$(this).addClass("success");
    var target = $(this);
    var tid = target.attr("data-teamid");
    var pid = target.val();
    var group = $("#group-" + tid)
    console.log("change:" + tid);

    $.ajax({
      type: 'POST',
      url: "/teams/set_plate_for/" + tid,
      data: "plateid=" + pid,
      success: function(result) {
        console.log(result);
        if (result === true) {
          group.fadeOut('slow', function() {
            group.removeClass("error").addClass("success").fadeIn('slow');
          });
        } else {
          group.fadeOut('slow', function() {
            group.removeClass("success").addClass("error").fadeIn('slow');
          });
        }
      }
    });

  });

});


