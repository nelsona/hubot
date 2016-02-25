# Description:
#   A way to get a count of the views of a piece of content from within Slack
#
# Commands:
#   gp-count content document name or Id - The name or Id are used to query the log to get a count of the number of views for the piece of content

Sequelize = require 'sequelize'
sequelize = new Sequelize('goodpractice-staging', 'gpdb2005user', 'gpdb2005user', {
  host: '10.10.10.12',
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
	console.log contentDocumentIdentifier
	sequelize.query('SELECT COUNT(*) as Count FROM LogEntry WHERE ContentId = :contentId AND Action = :action AND ActionDate > (SELECT DateAdd(yy, -1, GetDate()))', { replacements: { contentId: contentDocumentIdentifier, action: 'ViewOnline' },  type: sequelize.QueryTypes.SELECT })
	.then((results) =>
		console.log results
		msgData = {
			channel: res.message.room
			text: "#{ res.match[1] } : #{ results[0].Count }"
		}
		res.robot.adapter.customMessage msgData
	)
