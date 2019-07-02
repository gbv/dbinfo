$(function() {
  $("#suggest-dbkey").easyAutocomplete({
    url: function (searchTerms) {
      return BASE + "/api/dbkey?id=" + encodeURI(searchTerms)
    },
    getValue: "completion",
    template: {
	  type: "description",
	  fields: {
		description: "description"
	  }
	}      
  })

  $("#suggest-form").submit(function(event) {
    var url = BASE + "/" + $("#suggest-dbkey").val()
    window.location.href = url
  })
})
