# # Description:
# #   A way to clear the emec data from slack
# #
# # Configuration
# #   HUBOT_EMEC_MONGO_URL - Url of the mongodb to be updated
# #   HUBOT_EMEC_ELASTIC_URL - Url of the search index to be updated
# #
# # Commands:
# #   emec data - command to reset the data in emec database
# mongo = require 'then-mongo'
# q = require 'q'
# faker = require 'faker'
# randomId = require 'random-id'
#
# process.env.HUBOT_EMEC_MONGO_URL ||= 'mongodb://10.10.10.80:27017/emec-test'
# process.env.HUBOT_EMEC_ELASTIC_URL ||= 'http://10.10.10.110:9200'
#
# db = mongo process.env.HUBOT_EMEC_MONGO_URL, ['cases', 'courses', 'notifications', 'subscriptions','users']
#
# module.exports = (robot) ->
# 	robot.respond /emec data/i, (res) ->
# 		emecReset res
#
# emecReset = (res) ->
# 	promises = []
# 	# 1 Drop the existing emec database
# 	promises.push(db.cases.drop())
# 	promises.push(db.courses.drop())
# 	promises.push(db.notifications.drop())
# 	promises.push(db.subscriptions.drop())
# 	promises.push(db.users.drop())
#
# 	user = {}
#
# 	q.all(promises)
# 	.catch((err) ->
# 		return []
# 	)
# 	.then((results) ->
# 	# 2 Create new user
# 		user =
# 			createdAt:(new Date).getTime()
# 			username:'biofractalrnd.feide.no'
# 			emails: [{address:'janderson@goodpractice.com', verified:false}]
# 			profile:
# 				firstname : 'Jonny',
# 				lastname : 'Anderson',
# 				displayname : 'Jonny Anderson',
# 				domainId : 'openidp.feide.no.690aeb0f55a90db0f28e7dd8511e99a1dc8ebfe0',
# 				affiliation : 'guest',
# 				reads : ['emec-002']
# 		db.users.insert user
# 	)
# 	.then((result) ->
# 		user = result
# 		# 3 Create subscriptions
# 		subscriptions =
# 		[
# 			name:'OpenIdP'
# 			key:'openidp'
# 			idpUrl:'https://openidp.feide.no/simplesaml/saml2/idp/SSOService.php'
# 		,
# 			name:'TestShib'
# 			key:'testshib'
# 			idpUrl:'https://idp.testshib.org/idp/profile/SAML2/Redirect/SSO'
# 		,
# 			name:'SSOCircle'
# 			key:'ssocircle'
# 			idpUrl:'https://idp.ssocircle.com:443/sso/SSORedirect/metaAlias/ssocircle'
# 		]
# 		db.subscriptions.insert subscriptions
# 	)
# 	.then((result) ->
# 		# 4 Generate 5 new notifications
# 		recipients = [{_id: user._id, displayname:user.profile.displayname}]
# 		now = (new Date).getTime()
# 		notifications=[]
# 		count = 5
# 		for i in [1..count]
# 			paragraphs = rnd 2, 3
# 			message = faker.lorem.paragraphs paragraphs
# 			notification=
# 				created: new Date(now - (i * 3600 * 1000))
# 				title:"Notification -  #{ faker.lorem.sentence(3) }"
# 				message: message
# 				recipients: recipients
# 			notifications.push notification
# 		db.notifications.insert notifications
# 	)
# 	.then((result) ->
# 		# 5 Generate 20 new cases
# 		now = (new Date).getTime()
# 		caseStudies=[]
# 		count = 20
# 		for i in [1..count]
# 			authors = []
# 			authorCount = rnd(1, 3)
# 			for i in [1..authorCount]
# 				authors.push faker.name.findName()
# 			str = "" + i
# 			pad = "000"
# 			ans = pad.substring(0, pad.length - str.length) + str
# 			year = rnd 1990, 2015
# 			month = rnd 1, 12
# 			day  = rnd 1, 28
# 			caseStudy=
# 				articleId:"emec-#{ ans }"
# 				title: faker.lorem.sentence rnd(6, 20)
# 				authors: authors
# 				subject: faker.lorem.sentence(rnd(1, 5))
# 				published: new Date(year, month, day)
# 				copyright:"© #{year} Emerald Group Publishing Limited"
# 				keywords: faker.lorem.words(rnd(2, 6))
# 				publisher:"Emerald Group Publishing Limited"
# 				journal:'Emerald Emerging Markets Case Studies'
# 				supplements:[]
# 				likes: 0
# 				abstract: faker.lorem.paragraphs rnd(5, 10)
# 				body: content 10, 20
# 				acknowledgements: faker.lorem.paragraphs rnd(1, 5)
# 				appendices: faker.lorem.paragraphs rnd(1, 5)
# 				footnotes: faker.lorem.paragraphs rnd(1, 5)
# 				notes: faker.lorem.paragraphs rnd(1, 5)
# 				references: faker.lorem.paragraphs rnd(1, 5)
# 				teachingnotes: content 5, 10
# 			caseStudies.push caseStudy
# 		db.cases.insert caseStudies
# 	)
# 	.then((result) ->
# 		# 6 Generate 5 new courses
# 		now = (new Date).getTime()
# 		recipients = [{_id: user._id, displayname:user.profile.displayname}]
# 		courses=[]
# 		count = 5
# 		for i in [1..count]
# 			cases = result
# 			caseRefs=[]
# 			caseCount = rnd 3, 10
# 			for j in [1..caseCount]
# 				index = rnd 0, cases.length - 1
# 				caseStudy = cases[index]
# 				caseRefs.push
# 					caseId: caseStudy._id
# 					title: caseStudy.title
# 					abstract: caseStudy.abstract
# 					due: new Date(now - (rnd(10, 100)  * 3600 * 1000))
#
# 			course =
# 				created: new Date(now - (i * 3600 * 1000))
# 				name:"Course -  #{faker.lorem.sentence(rnd(1, 3))}"
# 				description: faker.lorem.paragraphs rnd(3, 10)
# 				instructor: faker.name.findName()
# 				cases: caseRefs
# 				students: recipients
# 				code: randomId 5,"aA0"
# 			courses.push course
# 		db.courses.insert courses
# 	)
# 	.then((result) ->
# 		res.send "Data reset"
# 	)
# 	.catch((err) ->
# 		console.log err
# 		res.send "Error in data reset"
# 	)
#
# rnd = (min, max)	->
# 	Math.floor Math.random() * (max - min+1) + min
#
# content = (min, max) ->
# 	sections = []
# 	while sections.length < max
# 		value = section 1,4
# 		sections.push value
# 		break if sections.length > min and rnd(1, 3) is 1
# 	count = if sections.length < max then sections.length else max
# 	sections.slice(0, count).join ''
#
# section = (min, max) ->
# 	sect=["<h3>#{faker.lorem.sentence rnd(2, 5)}</h3>"]
# 	sect.push "#{paragraph 5, 50}"
# 	count = rnd 1,5
# 	for [0...count-1]
# 		if rnd(1,5) is 1
# 			sect.push image()
# 			sect.push "#{styled 5, 50}"
# 		else if rnd(1,5) is 1
# 			sect.push list 3, 10
# 			sect.push "#{styled 5, 50}"
# 		else
# 			sect.push "#{styled 5, 50}"
# 	return sect
#
# styled = (min, max)->
# 	para = faker.lorem.paragraph rnd min, max
# 	para = style 3, 5, para, "b"
# 	para = style 1, 5, para, "i"
# 	para = link 1, 5, para
# 	return "<div>#{para}</div>"
#
# paragraph = (min, max, addStyle=true) ->
# 	para = faker.lorem.paragraph rnd min, max
# 	return "<div>#{para}</div>"
#
# image = (alt="dummy image 600x400", imageUrl="http://dummyimage.com/600x400/223344/fff.png") ->
# 	return "![alt text](#{imageUrl} '#{alt}')\n\n**#{alt}**\n\n"
#
# link = (min, max, content, url='http://google.com') ->
# 	count = rnd min, max
# 	words = content.split " "
# 	for [0...count]
# 		index = rnd 0, words.length-1
# 		words[index] = "<a href='http://google.com'>#{words[index]}</a>"
# 	return words.join " "
#
# list = (min, max) ->
# 	count = rnd min, max
# 	items=[]
# 	for [0...count]
# 		items.push "<li>#{faker.lorem.sentence rnd(2, 6)}</li>"
# 	return "<ul>#{items.join "\n"}</ul>"
#
#
# style = (min, max, content, tag) ->
# 	count = rnd min, max
# 	words = content.split " "
# 	for [0...count]
# 		index = rnd 0, words.length-1
# 		words[index] = "<#{tag}>#{words[index]}</#{tag}>"
# 	return words.join " "
#
# 	# 4 Generate 20 new cases
# 	# 5 Insert cases in to mongodb
# 	# 6 Insert cases in to elastic search
#
#
# 	# res.robot.http(process.env.HUBOT_GP_SEARCH_URL + "/content_all/item/_search")
# 	# .header('accept', 'application/json')
# 	# .post(postData) (err, response, body) ->
# 	# 	if err?
# 	# 		msgData = {
# 	# 			channel: res.message.room
# 	# 			text: "No Results for \"#{ res.match[1] }\""
# 	# 		}
# 	# 		res.robot.adapter.customMessage msgData
# 	#
# 	# 	promises = []
# 	# 	results = JSON.parse body
# 	# 	items = ({ id: item._id, title: item._source.title, summary: item._source.summary, type: item._source.type } for item in results.hits.hits)
# 	#
# 	# 	promises.push(getLinkKey(res, item)) for item in items
# 	#
# 	# 	q.all(promises).then(() ->
# 	# 		if items.length > 0
# 	# 			msgData = {
# 	# 				channel: res.message.room
# 	# 				text: "Results for #{ res.match[1] }"
# 	# 				attachments: []
# 	# 			}
# 	# 			msgData.attachments.push { fallback: "#{item.title} - #{item.summary}", title: item.title, title_link: "#{process.env.HUBOT_GP_APP_URL}/#/#{ process.env.HUBOT_GP_SUB_URL }/s/#{ item.key }", text: item.summary } for item in items
# 	# 		else
# 	# 			msgData = {
# 	# 				channel: res.message.room
# 	# 				text: "No Results for \"#{ res.match[1] }\""
# 	# 			}
# 	#
# 	# 		# post the message
# 	# 		res.robot.adapter.customMessage msgData
# 	# 	).catch(() ->
# 	# 		msgData = {
# 	# 			channel: res.message.room
# 	# 			text: "No Results for \"#{ res.match[1] }\""
# 	# 		}
# 	# 		res.robot.adapter.customMessage msgData
# 	# 	)
