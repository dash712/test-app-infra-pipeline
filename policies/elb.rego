package elb

{{.prefix}}elbAccessLoggingDisabled[elb.id] {
    elb := input.aws_elb[_]
    access_logs := elb.config.access_logs[_]
    access_logs.enabled != true
}