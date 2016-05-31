# Description:
#   Simple way to restart app on staging
#
# Commands:
#   restart-s simple way to restart app on staging
exec = require('ssh-exec')

module.exports = (robot) ->
	robot.respond /restart-s/i, (res) ->
		restartStaging res

restartStaging = (res) ->
	exec 'docker exec goodpractice-app pm2 restart app', 'administrator@10.10.10.110', (err, stdout, stderr) ->
		console.log err, stdout, stderr
		msgData =
			channel: res.message.room
			text: stdout
		res.robot.adapter.customMessage msgData
