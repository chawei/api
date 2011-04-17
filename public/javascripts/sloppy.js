
for(var i=0; i<reviews.length; i++) {
  var item = $('<div class="review_item"></div>');
  var profile = $('<div class="profile"><img src="'+ reviews[i].user.profile_image_url +'"/></div>');
  var item_info = $('<div class="item_info"></div>');
  item_info.append('<div class="user_name">'+reviews[i].user.name+'</div>');
	item_info.append('<div class="text">'+reviews[i].text+'</div>');
	
	item.append(profile);
	item.append(item_info);
  item.append('<div style="clear:both;"/>');
  $('#main').append(item);
}


	
