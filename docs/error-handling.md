# Errors

OperatorError distinguishes Invalid, Api(code, reason), Capacity and Transport.
404 is success for absent MoonApp; 409/429/5xx trigger retry. 401/403 terminate
the informer and invalidate readiness. HTTP or watch 410 forces full LIST.
Worker failures release their processing key before requeue. Retry starts at
100ms and caps at 25.6s; Watch adds bounded random jitter. Capacity failure
forces recovery instead of silent event drops. In-memory work is restored by
initial LIST after restart.
