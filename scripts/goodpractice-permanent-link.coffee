# Description:
#   A way to get a count of the views of a piece of content from within Slack
#
# Commands:
#   permanent-link key - The key of the link that is to be made permanent

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
	robot.respond /permanent-link (.*)/i, (res) ->
		gpCount res

gpCount = (res) ->
	identifier = res.match[1]
	sequelize.query('UPDATE LinkShared SET DaysValid = -1 WHERE [Key] = :identifier', { replacements: { identifier: identifier },  type: sequelize.QueryTypes.RAW })
	.then((results) =>
		msgData = {
			channel: res.message.room
			text: "Link with Key: #{ identifier } has been set to be permanent"
		}
		res.robot.adapter.customMessage msgData
	)
