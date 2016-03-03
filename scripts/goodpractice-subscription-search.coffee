# Description:
#   A way to get a count of the views of a piece of content from within Slack
#
# Commands:
#   subscription-url returns subscription data for this subscription url
#   subscription-id returns subscription data for this subscription id

process.env.DATABASE_NAME ||= 'goodpractice-staging'
process.env.DATABASE_USER ||= 'gpdb2005user'
process.env.DATABASE_PASSWORD ||= 'gpdb2005user'

Sequelize = require 'sequelize'
sequelize = new Sequelize(process.env.DATABASE_NAME, process.env.DATABASE_USER, process.env.DATABASE_PASSWORD, {
  host: '10.10.10.12',
  dialect: 'mssql',

  pool: {
    max: 5,
    min: 0,
    idle: 10000
  }
});


module.exports = (robot) ->
	robot.respond /subscription-url (.*)/i, (res) ->
		sql = 'SELECT Id, Name, SubscriptionUrl FROM Subscription WHERE SubscriptionUrl = :identifier'
		gpSubscriptionSql res, sql

	robot.respond /subscription-id (.*)/i, (res) ->
		sql = 'SELECT Id, Name, SubscriptionUrl FROM Subscription WHERE Id = :identifier'
		gpSubscriptionSql res, sql

gpSubscriptionSql = (res, sql) ->
	identifier = res.match[1]
	sequelize.query(sql, { replacements: { identifier: identifier },  type: sequelize.QueryTypes.SELECT })
	.then((results) =>
		msgData = {
			channel: res.message.room
			text: "Results for: #{ res.match[1] }"
			attachments: []
		}
		msgData.attachments.push { fallback: "#{item.Name} - #{item.SubscriptionUrl} - #{item.Id}", title: item.Name, text: "Id: #{ item.Id }\n Name: #{ item.Name}\n Url: #{ item.SubscriptionUrl }" } for item in results

		res.robot.adapter.customMessage msgData
	)
