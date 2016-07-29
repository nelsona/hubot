# Description:
#   A way to get a count of the views of a piece of content from within Slack
#
# Commands:
#   gp-count content document name or Id - The name or Id are used to query the log to get a count of the number of views for the piece of content in the last year

process.env.DATABASE_NAME ||= 'goodpractice-staging'

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


module.exports = (robot) ->
	robot.respond /gp-count (.*)/i, (res) ->
		gpCount res

gpCount = (res) ->
	contentDocumentIdentifier = res.match[1]
	sequelize.query('SELECT COUNT(*) as Count FROM LogEntry WHERE ContentId = :contentId AND Action = :action AND ActionDate > (SELECT DateAdd(yy, -1, GetDate()))', { replacements: { contentId: contentDocumentIdentifier, action: 'ViewOnline' },  type: sequelize.QueryTypes.SELECT })
	.then((results) =>
		msgData = {
			channel: res.message.room
			text: "#{ res.match[1] } : #{ results[0].Count }"
		}
		res.robot.adapter.customMessage msgData
	)
