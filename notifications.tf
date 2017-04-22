# Configuration for automatic notifications from AWS infrastructure.

# An "SNS topic" is essentially "topic" to which you can send
# notifications, and to which you can subscribe.  This is our generic topic
# for administrative updates.
#
# You need to subscribe to this topic manually using the AWS web console,
# because Terraform can't handle email or pager confirmations.  To
# subscribe, go to
# https://console.aws.amazon.com/sns/v2/home?region=us-east-1#/topics and
# check the topic.  Then use "Actions > Subscribe" and add your email
# address or SMS number.
resource "aws_sns_topic" "admin_updates" {
  name = "admin-updates"
}


