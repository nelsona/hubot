# Description:
#   A way to get a count of the views of a piece of content from within Slack
#
# Commands:
#   gp-count content document name or Id - The name or Id are used to query the log to get a count of the number of views for the piece of content

process.env.DATABASE_NAME ||= 'goodpractice-staging'

json2csv = require 'json2csv'
Sequelize = require 'sequelize'
sequelize = new Sequelize(process.env.DATABASE_NAME, process.env.DATABASE_USER, process.env.DATABASE_PASSWORD, {
  host: process.env.DATABASE_SERVER,
  dialect: 'mssql',

  pool: {
    max: 5,
    min: 0,
    idle: 10000
  }
});

fields = ['Content', 'User', 'Comment' , 'Date']
sql = "select ci.Name AS Content, cm.UserName AS [User], cm.CreationDate as Date, cm.Xhtml AS Comment from Comment cm \
INNER JOIN _Collection c1 on cm.Id = c1.Id \
INNER JOIN _Dom d1 on c1.CollectionId = d1.Id \
INNER JOIN ContentItem ci on d1.ParentId = ci.Id \
WHERE cm.UrlName = :subscriptionUrl \
AND cm.CreationDate > DATEADD(day, 1, EOMONTH(DATEADD(month, -2, GETDATE()))) \
AND cm.CreationDate < EOMONTH(DATEADD(month, -1, GETDATE()))"

module.exports = (robot) ->
	robot.respond /gp-comments (.*)/i, (res) ->
		gpComments res

gpComments = (res) ->
	subscriptionId = res.match[1]
	sequelize.query('SELECT Name, SubscriptionUrl FROM Subscription WHERE Id = :subscriptionId', { replacements: { subscriptionId: subscriptionId },  type: sequelize.QueryTypes.SELECT })
	.then((results) =>
		sequelize.query(sql, { replacements: { subscriptionUrl: results[0].SubscriptionUrl },  type: sequelize.QueryTypes.SELECT })
			.then((subscription) =>
				json2csv({data: subscription, fields: fields, quotes: ''}, (err, csv) =>
					msgData = {
						channel: res.message.room
						text: "*Results for #{results[0].Name}*\n" + csv
					}
					res.robot.adapter.customMessage msgData
				)
			)
	)
