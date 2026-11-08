# Errors

OperatorError distinguishes Invalid, Api(code, reason), general Capacity,
CacheCapacity, QueueCapacity, ListCapacity and Transport.
404 is success for absent MoonApp when handled by the application; 409/429/5xx
trigger retry. Permanent HTTP failures terminate the informer and invalidate
readiness. HTTP or watch 410 forces full LIST.
Worker failures release their processing key before requeue. Retry starts at
100ms and caps at 25.6s; Watch adds bounded random jitter. QueueCapacity yields
to workers at admission. Cache/List/general capacity failures invalidate readiness
and terminate the informer without repeated LIST; they are never HTTP 410.
In-memory work is restored by
initial LIST after restart.
LIST TypeMeta omitted by built-in serializers is filled from the requested
endpoint; explicit type mismatches remain invalid. Non-JSON proxy error bodies
retain their HTTP status. Malformed watch records force relist instead of
reconnecting indefinitely to the same poison record. Three consecutive malformed
watch attempts terminate; a successfully accepted event resets this budget.
Invalid LIST data terminates immediately. Admission pressure yields
to workers while retaining the event and only then advances the checkpoint.
Requeue delay starts at reconcile completion, not request start.
Workers apply a default 30-second cooperative deadline. Invalid/Capacity and
permanent API errors produce Terminal rather than automatic retry; new events
can schedule the key again. Timed-out finalizer cleanup retains the finalizer.
