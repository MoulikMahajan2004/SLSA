#using the cloud watch to monitor the logs and set alarms for any abnormal activities
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/secure-cicd"
  retention_in_days = 30

  tags = {
    Name = "secure-cicd-cloudwatch-logs"
  }
}
#creating the alarm for ec2 cpu ustilization
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm" {
  alarm_name          = "secure-cicd-ec2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 2

  alarm_description = "Monitors abnormal EC2 CPU utilization"

  dimensions = {
    InstanceId = aws_instance.tfinstance.id
  }
}