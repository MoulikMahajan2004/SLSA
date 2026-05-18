#using the cloud watch to monitor the logs and set alarms for any abnormal activities
resource "random_id" "log_suffix" {
  byte_length = 4
}
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/cloudtrail-logs"
  retention_in_days = 30

  tags = {
    Name = "secure-cicd-cloudwatch-logs"
  }
}
#creating the alarm for ec2 cpu ustilization
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm" {
  alarm_name          = "ec2-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 2

  alarm_description = "Monitors abnormal EC2 CPU utilization"
  alarm_actions = [aws_sns_topic.security_alerts.arn]
  ok_actions    = [aws_sns_topic.security_alerts.arn]
  dimensions = {
    InstanceId = aws_instance.tfinstance.id
  }
}
# TRIGGERING ALRAM TO SEND ME AN EMAIL 
resource "aws_sns_topic" "security_alerts" {
  name = "alarm-trigger-sns"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "moulikmahajan2004@gmail.com"
}