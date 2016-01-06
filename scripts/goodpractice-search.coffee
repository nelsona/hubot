# Description:
#   A way to search within GP from slack
#
# Configuration
#   HUBOT_GP_SEARCH_URL - Url of the search index to be used
#   HUBOT_GP_USER_ID - User Id that will be used to generate the shared links
#   HUBOT_GP_SUB_URL - Subscription url for the client
#		HUBOT_GP_SUB_SSO - Is the subscription SSO enabled?
#		HUBOT_GP_API_URL - Url of the GP API
#		HUBOT_GP_API_KEY - API key used to generate the shared links
#
# Commands:
#   gp search terms - the search terms are extracted and a search is performed. The title and summary of the top 3 results
#		are returned in the message, along with a url to get to the content.

q = require 'q'

process.env.HUBOT_GP_SEARCH_URL ||= 'http://10.10.10.70:9200'
process.env.HUBOT_GP_USER_ID ||= 'c5977c1f-303a-0057-b69d-a27d00b8fe8a'
process.env.HUBOT_GP_SUB_URL ||= 'dev1'
process.env.HUBOT_GP_SUB_ID ||= '9DE83841-76C8-004D-8D7B-A3BF00AE8204'
process.env.HUBOT_GP_SUB_SSO ||= false
process.env.HUBOT_GP_API_URL ||= 'http://localhost:8082'
process.env.HUBOT_GP_APP_URL ||= 'http://localhost:3000'

module.exports = (robot) ->
	robot.respond /gp (.*)/i, (res) ->
		gpMe res

gpMe = (res) ->
	postData = getSearchBody { terms: res.match[1], subscriptionId: process.env.HUBOT_GP_SUB_ID }
	res.robot.http(process.env.HUBOT_GP_SEARCH_URL + "/content_all/item/_search")
	.header('accept', 'application/json')
	.post(postData) (err, response, body) ->
		if err?
			msgData = {
				channel: res.message.room
				text: "Error from search for \"#{ res.match[1] }\""
			}
			res.robot.adapter.customMessage msgData

		promises = []
		results = JSON.parse body
		items = ({ id: item._id, title: item._source.title, summary: item._source.summary, type: item._source.type } for item in results.hits.hits)

		promises.push(getLinkKey(res, item)) for item in items

		q.all(promises).then(() ->
			if items.length > 0
				msgData = {
					channel: res.message.room
					text: "Results for #{ res.match[1] }"
					attachments: []
				}
				msgData.attachments.push { fallback: "#{item.title} - #{item.summary}", title: item.title, title_link: "#{process.env.HUBOT_GP_APP_URL}/#/#{ process.env.HUBOT_GP_SUB_URL }/s/#{ item.key }", text: item.summary } for item in items
			else
				msgData = {
					channel: res.message.room
					text: "No items returned for \"#{ res.match[1] }\""
				}

			# post the message
			res.robot.adapter.customMessage msgData
		).catch(() ->
			msgData = {
				channel: res.message.room
				text: "Error when executing promises for \"#{ res.match[1] }\""
			}
			res.robot.adapter.customMessage msgData
		)

getSearchBody = (search) ->
	searchBody = {
		_source: {
			exclude: [
				"subscriptionId",
				"body",
				"author"
			]
		},
		query: {
			filtered: {
				query: {
					multi_match: {
						query: search.terms,
						type: "phrase",
						fields: [
							"title^4",
							"keywords^3",
							"summary^2",
							"body^1",
							"tags"
						]
					}
				},
				filter: {
					bool:{
						must: [ {term: { subscriptionId: search.subscriptionId }} ]
						must_not: []
					}
				}
			}
		},
		from: 0,
		size: 3
	}

	return JSON.stringify(searchBody)

getLinkKey = (res, item) ->
		deferred = q.defer();
		res.robot.http("#{process.env.HUBOT_GP_API_URL}/shared-link/generate/hubot/#{process.env.HUBOT_GP_USER_ID}/#{process.env.HUBOT_GP_SUB_URL}/#{item.id}/#{item.type}/14/false/#{process.env.HUBOT_GP_SUB_SSO}/#{process.env.HUBOT_GP_API_KEY}").post() (err, res, body) ->
				if (err)
					console.log err
					deferred.reject()
				else
					item.key = JSON.parse(body).Key
					deferred.resolve();

		return deferred.promise
