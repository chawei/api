
for(var i=0; i<reviews.length; i++) {
  var item = $('<div class="review_item"></div>');
  var profile = $('<div class="profile"><img src="'+ reviews[i].user.profile_image_url +'"/></div>');
  var user_name = $('<div class="user_name">'+reviews[i].user.name+'</div>');
	var text = $('<div class="text">'+reviews[i].text+'</div>');
	var created_at = $('<div class="created_at">'+reviews[i].created_at+'</div>');
	
	item.append(profile);
	item.append(user_name);
	item.append(text);
	item.append(created_at);
  
  $('#main').append(item);
}


	
