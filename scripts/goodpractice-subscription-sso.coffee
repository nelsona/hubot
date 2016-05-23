# Description:
#   A way to get a count of the views of a piece of content from within Slack
#
# Commands:
#   subscription-sso-get returns subscription SSO data for this subscription url
#   subscription-sso-set sets the SSO data for this subscription url. Needs to pass in three bits of data, subscriptionUrl, Certificate name and IdP Url. These need to be separated by spaces.

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
	robot.respond /sso-get (.*)/i, (res) ->
		identifier = res.match[1]
		sql = 'SELECT SubscriptionUrl, Name, IdentityProviderCertificateFile, IdentityProviderDestinationUrl FROM Subscription WHERE SubscriptionUrl = :identifier'
		getSSOSql res, identifier, sql

	robot.respond /sso-set (.*)/i, (res) ->
		update = 'UPDATE Subscription SET IdentityProviderCertificateFile = :certificate, IdentityProviderDestinationUrl = :url WHERE SubscriptionUrl = :identifier'
		select = 'SELECT SubscriptionUrl, Name, IdentityProviderCertificateFile, IdentityProviderDestinationUrl FROM Subscription WHERE SubscriptionUrl = :identifier'
		setSSOSql res, update, select

setSSOSql = (res, update, select) ->
	values = res.match[1].split(' ')
	sequelize.query(update, { replacements: { identifier: values[0], certificate: values[1], url: values[2] },  type: sequelize.QueryTypes.RAW })
	.then((results) =>
		return getSSOSql res, values[0], select
	)

getSSOSql = (res, identifier, sql) ->
	sequelize.query(sql, { replacements: { identifier: identifier },  type: sequelize.QueryTypes.SELECT })
	.then((results) =>
		msgData = {
			channel: res.message.room
			text: "Results for: #{ identifier }"
			attachments: []
		}
		msgData.attachments.push { fallback: "#{item.Name} - #{item.SubscriptionUrl}", title: item.Name, text: "Name: #{ item.Name}\n SSOCertificate: #{ item.IdentityProviderCertificateFile }\n SSOUrl: #{ item.IdentityProviderDestinationUrl }" } for item in results

		res.robot.adapter.customMessage msgData
	)
